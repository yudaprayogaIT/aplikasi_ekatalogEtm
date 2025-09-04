// lib/screens/status_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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

  // admin whatsapp (international format)
  final String adminPhoneIntl = '6285788837057';

  @override
  void initState() {
    super.initState();
    _determineStatus();
    _startPolling(); // mulai polling periodik (5 detik)
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

  Future<void> _determineStatus({bool onlyUpdate = false}) async {
    try {
      final res = await supabase
          .from('owners')
          .select('status,approved,is_active,approved_at,rejected_at')
          .eq('phone', widget.phone)
          .maybeSingle();

      if (res == null) {
        if (!onlyUpdate) {
          setState(() {
            status = AccountStatus.unknown;
            debugMsg = 'Owner record tidak ditemukan.';
          });
        }
        return;
      }

      if (res is Map) {
        // prefer status column if present
        if (res.containsKey('status') && res['status'] != null) {
          final s = res['status'].toString().toLowerCase();
          _applyStatusString(s);
          return;
        }

        if (res.containsKey('approved') && res['approved'] is bool) {
          final approved = res['approved'] as bool;
          setState(() => status = approved ? AccountStatus.approved : AccountStatus.pending);
          return;
        }

        if (res.containsKey('is_active') && res['is_active'] is bool) {
          final active = res['is_active'] as bool;
          setState(() => status = active ? AccountStatus.approved : AccountStatus.pending);
          return;
        }

        if (res.containsKey('approved_at') && res['approved_at'] != null) {
          setState(() => status = AccountStatus.approved);
          return;
        }

        if (res.containsKey('rejected_at') && res['rejected_at'] != null) {
          setState(() => status = AccountStatus.rejected);
          return;
        }

        // default
        setState(() {
          status = AccountStatus.pending;
          debugMsg = 'Tidak ada field status eksplisit — dianggap pending.';
        });
        return;
      }

      if (!onlyUpdate) {
        setState(() {
          status = AccountStatus.unknown;
          debugMsg = 'Response DB tak terduga: ${res.runtimeType}';
        });
      }
    } catch (e, stack) {
      // gunakan stack jika ingin logging, atau ganti menjadi `catch (e)` jika tidak perlu
      // ignore: avoid_print
      print('[StatusScreen] _determineStatus error: $e\n$stack');
      if (!onlyUpdate) {
        setState(() {
          status = AccountStatus.error;
          debugMsg = 'Error saat memeriksa status: $e';
        });
      }
    }
  }

  void _applyStatusString(String s) {
    if (s.contains('pend') || s == 'pending') {
      setState(() => status = AccountStatus.pending);
    } else if (s.contains('rej') || s == 'rejected' || s == 'denied') {
      setState(() => status = AccountStatus.rejected);
    } else if (s.contains('app') || s == 'approved' || s == 'active') {
      setState(() => status = AccountStatus.approved);
    } else {
      setState(() {
        status = AccountStatus.pending;
        debugMsg = 'Status "$s" tidak dikenali — dianggap pending.';
      });
    }
  }

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse(
        'https://wa.me/$adminPhoneIntl?text=${Uri.encodeComponent("Halo Admin, saya ingin menanyakan alasan penolakan akun saya. Nomor: ${widget.phone}")}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak dapat membuka WhatsApp')));
    }
  }

  void _goHomeClearingStack() {
    Navigator.of(context).pushNamedAndRemoveUntil(StatusScreen.rootRoute, (r) => false);
  }

  void _goToAppHome() {
    Navigator.of(context).pushNamedAndRemoveUntil(StatusScreen.homeRoute, (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    // Redirect if approved
    if (status == AccountStatus.approved) {
      Future.microtask(() => _goToAppHome());
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_titleForStatus(status)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(child: _buildBodyForStatus()),
      bottomNavigationBar: _buildBottomNav(context, 3),
    );
  }

  String _titleForStatus(AccountStatus s) {
    switch (s) {
      case AccountStatus.pending:
        return 'Akun Pending';
      case AccountStatus.rejected:
        return 'Akun Ditolak';
      case AccountStatus.loading:
        return 'Memeriksa Status';
      case AccountStatus.approved:
        return 'Mengalihkan...';
      case AccountStatus.unknown:
      case AccountStatus.error:
      default:
        return 'Status Akun';
    }
  }

  Widget _buildBodyForStatus() {
    if (status == AccountStatus.loading) return const Center(child: CircularProgressIndicator());

    if (status == AccountStatus.error || status == AccountStatus.unknown) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 32),
            Icon(Icons.error_outline, size: 120, color: Colors.grey[300]),
            const SizedBox(height: 20),
            const Text('Terjadi masalah saat membaca status akun.', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            if (debugMsg != null) Text(debugMsg!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24),
              child: Column(
                children: [
                  OutlinedButton(onPressed: () => _determineStatus(onlyUpdate: false), child: const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Coba lagi'))),
                  const SizedBox(height: 12),
                  ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB11F23)), onPressed: _goHomeClearingStack, child: const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Kembali ke Beranda'))),
                ],
              ),
            )
          ],
        ),
      );
    }

    if (status == AccountStatus.pending) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 24),
            SizedBox(height: 220, child: Center(child: Icon(Icons.people_alt, size: 140, color: Colors.grey[300]))),
            const SizedBox(height: 20),
            const Text('Pendaftaran Anda sedang diproses oleh admin.', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton(onPressed: _goHomeClearingStack, child: const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Kembali ke Beranda'))),
                  const SizedBox(height: 12),
                  ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.black87), onPressed: () {
                    try { Supabase.instance.client.auth.signOut(); } catch (_) {}
                    _goHomeClearingStack();
                  }, child: const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Keluar'))),
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
          const SizedBox(height: 24),
          SizedBox(height: 220, child: Center(child: Icon(Icons.sentiment_dissatisfied, size: 140, color: Colors.grey[300]))),
          const SizedBox(height: 20),
          const Text('Maaf, pendaftaran Anda tidak dapat kami proses.', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: ElevatedButton.icon(
              // NOTE: replaced Icons.whatsapp (tidak tersedia) dengan Icons.call
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB11F23), padding: const EdgeInsets.symmetric(vertical: 12)),
              onPressed: _openWhatsApp,
              icon: const Icon(Icons.call, size: 18),
              label: const Text('Hubungi Admin', style: TextStyle(fontSize: 16)),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: OutlinedButton(onPressed: _goHomeClearingStack, child: const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Kembali ke Beranda'))),
          )
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
            // Already status/profile
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.grid_view_outlined), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: ''),
      ],
    );
  }
}
