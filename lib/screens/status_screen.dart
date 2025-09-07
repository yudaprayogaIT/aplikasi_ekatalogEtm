// lib/screens/status_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';

enum AccountStatus { loading, pending, rejected, approved, unknown, error }

class StatusScreen extends StatefulWidget {
  final String phone;
  static const String routeName = '/status';
  static const String homeRoute = '/home';
  static const String rootRoute = '/';

  const StatusScreen({super.key, required this.phone});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  final supabase = Supabase.instance.client;
  AccountStatus status = AccountStatus.loading;
  String? debugMsg;
  Timer? _pollTimer;

  // admin WhatsApp (international, tanpa +)
  final String adminPhoneIntl = '6285788837057';

  // asset paths (update sesuai lokasi asetmu)
  static const String pendingAsset = 'assets/images/status_pending.png';
  static const String rejectedAsset = 'assets/images/status_rejected.png';

  @override
  void initState() {
    super.initState();
    _determineStatus(); // initial fetch
    _startPolling(); // periodik every 5s
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _determineStatus(onlyUpdate: true);
    });
  }

  Future<String?> _fetchStatusFromDb(String phone) async {
    try {
      dynamic res;
      try {
        res = await supabase
            .from('owners')
            .select('status')
            .eq('phone_number', phone)
            .maybeSingle();
      } catch (_) {
        res = await supabase
            .from('owners')
            .select('status')
            .eq('phone_number', phone)
            .limit(1);
      }

      if (res == null) return null;

      try {
        final data = (res as dynamic).data;
        if (data != null) {
          if (data is Map && data.containsKey('status')) {
            return data['status']?.toString();
          } else if (data is List && data.isNotEmpty) {
            final first = data.first;
            if (first is Map && first.containsKey('status')) {
              return first['status']?.toString();
            }
          }
        }
      } catch (_) {}

      if (res is Map && res.containsKey('status')) {
        return res['status']?.toString();
      }

      if (res is List && res.isNotEmpty) {
        final first = res.first;
        if (first is Map && first.containsKey('status')) {
          return first['status']?.toString();
        }
      }

      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _determineStatus({bool onlyUpdate = false}) async {
    try {
      final statusStr = await _fetchStatusFromDb(widget.phone);

      if (statusStr == null) {
        if (!onlyUpdate) {
          setState(() {
            status = AccountStatus.unknown;
            debugMsg =
                'Owner record tidak ditemukan untuk nomor ${widget.phone}.';
          });
        }
        return;
      }

      final norm = statusStr.trim().toLowerCase();

      if (norm == 'pending') {
        setState(() {
          status = AccountStatus.pending;
          debugMsg = null;
        });
        return;
      } else if (norm == 'rejected') {
        setState(() {
          status = AccountStatus.rejected;
          debugMsg = null;
        });
        return;
      } else if (norm == 'active' || norm == 'approved') {
        setState(() {
          status = AccountStatus.approved;
          debugMsg = null;
        });
        _pollTimer?.cancel();
        Future.microtask(() => _goToAppHome());
        return;
      } else {
        setState(() {
          status = AccountStatus.pending;
          debugMsg = 'Status "$statusStr" tidak dikenali — dianggap pending.';
        });
        return;
      }
    } catch (e, st) {
      // ignore: avoid_print
      print('[StatusScreen] _determineStatus error: $e\n$st');
      if (!onlyUpdate) {
        setState(() {
          status = AccountStatus.error;
          debugMsg = 'Error saat memeriksa status: $e';
        });
      }
    }
  }

  /// Membuka WhatsApp. Strategy:
  /// 1) coba scheme whatsapp:// (buka aplikasi)
  /// 2) fallback ke https://wa.me/...
  /// 3) fallback ke https://api.whatsapp.com/send?...
  /// Jika semua gagal, tampilkan SnackBar dengan instruksi manual.
  Future<void> _openWhatsApp() async {
    final message =
        'Halo Admin, \n\n Saya ingin menanyakan alasan penolakan akun saya saat mendaftar di Aplikasi Ekatalog ETM. Mohon bantuannya.\nBerikut nomor saya: ${widget.phone}';
    final whatsappScheme = Uri.parse(
      'whatsapp://send?phone=$adminPhoneIntl&text=${Uri.encodeComponent(message)}',
    );
    final intentUriStr =
        'intent://send?phone=$adminPhoneIntl&text=${Uri.encodeComponent(message)}#Intent;package=com.whatsapp;scheme=whatsapp;end';
    final intentUri = Uri.parse(intentUriStr);
    final waMeUri = Uri.parse(
      'https://wa.me/$adminPhoneIntl?text=${Uri.encodeComponent(message)}',
    );
    final apiUri = Uri.parse(
      'https://api.whatsapp.com/send?phone=$adminPhoneIntl&text=${Uri.encodeComponent(message)}',
    );

    // helper untuk mencoba launch dan menangkap hasil
    Future<bool> tryLaunch(
      Uri uri, {
      LaunchMode mode = LaunchMode.externalApplication,
    }) async {
      try {
        // catat untuk debugging
        // ignore: avoid_print
        print('[StatusScreen] trying launch -> $uri');
        final ok = await launchUrl(uri, mode: mode);
        // ignore: avoid_print
        print('[StatusScreen] launch result: $ok for $uri');
        return ok;
      } catch (e) {
        // ignore: avoid_print
        print('[StatusScreen] launch error for $uri -> $e');
        return false;
      }
    }

    // 1) try whatsapp:// (app)
    if (await tryLaunch(whatsappScheme)) return;

    // 2) try intent:// (force package) — Android specific, may be blocked on some devices
    if (await tryLaunch(intentUri)) return;

    // 3) try wa.me (browser which often redirects to app)
    if (await tryLaunch(waMeUri)) return;

    // 4) try api.whatsapp.com
    if (await tryLaunch(apiUri)) return;

    // semua gagal -> beri dialog dengan opsi manual
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tidak dapat membuka WhatsApp'),
        content: Text(
          'Perangkat ini tidak mengizinkan membuka WhatsApp secara otomatis.\n\nSilakan hubungi: +$adminPhoneIntl',
        ),
        actions: [
          TextButton(
            onPressed: () {
              // salin nomor
              Clipboard.setData(ClipboardData(text: '+$adminPhoneIntl'));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Nomor admin disalin ke clipboard'),
                ),
              );
            },
            child: const Text('Salin Nomor'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // buka wa.me di browser sebagai opsi manual
              launchUrl(waMeUri, mode: LaunchMode.externalApplication);
            },
            child: const Text('Buka di Browser'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOutAndReturnHome() async {
    try {
      try {
        await supabase.auth.signOut();
      } catch (_) {}
    } finally {
      _goHomeClearingStack();
    }
  }

  void _goHomeClearingStack() {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(StatusScreen.rootRoute, (r) => false);
  }

  void _goToAppHome() {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(StatusScreen.homeRoute, (r) => false);
  }

  // String _titleForStatus(AccountStatus s) {
  //   switch (s) {
  //     case AccountStatus.pending:
  //       return 'Akun Pending';
  //     case AccountStatus.rejected:
  //       return 'Akun Ditolak';
  //     case AccountStatus.loading:
  //       return 'Memeriksa Status';
  //     case AccountStatus.approved:
  //       return 'Mengalihkan...';
  //     case AccountStatus.unknown:
  //       return 'Status Akun';
  //     case AccountStatus.error:
  //       return 'Status Akun';
  //   }
  //   return 'Status Akun';
  // }

  Widget _imageWithFallback(
    String assetPath,
    IconData fallbackIcon, {
    double? width,
    double? height,
  }) {
    return Image.asset(
      assetPath,
      fit: BoxFit.contain,
      width: width,
      height: height,
      errorBuilder: (ctx, err, stack) {
        return Icon(
          fallbackIcon,
          size: (height ?? 120) * 0.75,
          color: Colors.grey[300],
        );
      },
    );
  }

  Widget _buildBodyForStatus() {
    if (status == AccountStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (status == AccountStatus.error || status == AccountStatus.unknown) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 32),
            Icon(Icons.error_outline, size: 120, color: Colors.grey[300]),
            const SizedBox(height: 20),
            const Text(
              'Terjadi masalah saat membaca status akun.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (debugMsg != null)
              Text(
                debugMsg!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 28.0,
                vertical: 24,
              ),
              child: Column(
                children: [
                  OutlinedButton(
                    onPressed: () => _determineStatus(onlyUpdate: false),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Coba lagi'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB11F23),
                    ),
                    onPressed: _goHomeClearingStack,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Kembali ke Beranda'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (status == AccountStatus.pending) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const Spacer(),
            const Text(
              'Pendaftaran Anda sedang diproses oleh admin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
                fontSize: 16,
              ),
            ),
            // const SizedBox(height: 10),
            SizedBox(
              height: 250,
              child: Center(
                child: _imageWithFallback(pendingAsset, Icons.people_alt),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton(
                    onPressed: _goHomeClearingStack,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Kembali ke Beranda',
                        style: TextStyle(color: Color(0xFFB11F23)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFDD100),
                    ),
                    onPressed: _signOutAndReturnHome,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Keluar',
                        style: TextStyle(
                          color: Colors.black,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Rejected
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const Spacer(),
          const Text(
            'Maaf, pendaftaran Anda tidak dapat kami proses.',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 10), // Row: image left, button right
          SizedBox(
            height: 250,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // gambar kiri
                Expanded(
                  flex: 1,
                  child: Center(
                    child: _imageWithFallback(
                      rejectedAsset,
                      Icons.sentiment_dissatisfied,
                    ),
                  ),
                ),
                const SizedBox(width: 12), // tombol kanan
                Expanded(
                  flex: 1,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB11F23),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                      ),
                      onPressed: _openWhatsApp,
                      icon: const Icon(FontAwesomeIcons.whatsapp, size: 18),
                      label: const Text(
                        'Hubungi Admin',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: ElevatedButton(
              onPressed: _goHomeClearingStack,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFDD100),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Kembali ke Beranda',
                  style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, int currentIndex) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: (i) {
        switch (i) {
          case 0:
            Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
            break;
          case 1:
            Navigator.of(context).pushNamed('/catalog');
            break;
          case 2:
            Navigator.of(context).pushNamed('/favorites');
            break;
          case 3:
            // already here
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: ''),
        BottomNavigationBarItem(
          icon: Icon(Icons.grid_view_outlined),
          label: '',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: ''),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // If already approved, show a spinner while redirecting
    if (status == AccountStatus.approved) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      // appBar: AppBar(
      //   title: Text(_titleForStatus(status)),
      //   backgroundColor: Colors.white,
      //   foregroundColor: Colors.black87,
      //   elevation: 0,
      //   leading: IconButton(
      //     icon: const Icon(Icons.arrow_back, color: Colors.black87),
      //     onPressed: () => Navigator.of(context).maybePop(),
      //   ),
      // ),
      body: SafeArea(child: _buildBodyForStatus()),
      bottomNavigationBar: _buildBottomNav(context, 3),
    );
  }
}
