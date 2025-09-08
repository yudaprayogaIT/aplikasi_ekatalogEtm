// sebelum menggunakan OTP Firebase Authentication by google
// lib/screens/register_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/primary_button.dart';
import 'status_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController phoneCtrl = TextEditingController();
  final supabase = Supabase.instance.client;

  // Jika true, navigasi ke StatusScreen menggunakan named route '/status'
  // Jika false, navigasi menggunakan constructor: StatusScreen(phone: ...)
  static const bool useNamedRoute = false;

  String generatedOtp = "1234"; // dummy otp

  bool loading = false;
  bool checking = false;

  Timer? _debounceTimer;
  bool isRegisteredActive = false;
  String? _knownStatus;

  bool get isPhoneValid {
    final phone = phoneCtrl.text.trim();
    return phone.isNotEmpty && phone.length >= 10 && phone.startsWith("08");
  }

  @override
  void initState() {
    super.initState();
    phoneCtrl.addListener(_onPhoneChanged);
  }

  @override
  void dispose() {
    phoneCtrl.removeListener(_onPhoneChanged);
    _debounceTimer?.cancel();
    phoneCtrl.dispose();
    super.dispose();
  }

  void _onPhoneChanged() {
    setState(() {
      isRegisteredActive = false;
      _knownStatus = null;
    });

    _debounceTimer?.cancel();
    if (!isPhoneValid) return;
    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      _checkPhoneSilent(phoneCtrl.text.trim());
    });
  }

  Future<void> _checkPhoneSilent(String phone) async {
    setState(() => checking = true);
    try {
      final status = await _fetchOwnerStatusByPhone(phone);
      _knownStatus = status;
      final norm = (status ?? '').toString().trim().toLowerCase();

      // Exact-match semantics: only these exact values (after trim/lower) count
      final isActive = norm == 'active';
      if (isActive) {
        setState(() => isRegisteredActive = true);
      } else {
        setState(() => isRegisteredActive = false);
      }
    } catch (e) {
      // ignore silent errors
    } finally {
      if (mounted) setState(() => checking = false);
    }
  }

  /// Mengambil kolom status dari tabel owners berdasarkan phone.
  /// Mengembalikan null bila tidak ditemukan.
  Future<String?> _fetchOwnerStatusByPhone(String phone) async {
    try {
      dynamic res;
      try {
        res = await supabase
            .from('owners')
            .select('status')
            .eq('phone_number', phone)
            .maybeSingle();
      } catch (_) {
        // fallback: select limit 1
        res = await supabase
            .from('owners')
            .select('status')
            .eq('phone_number', phone)
            .limit(1);
      }

      if (res == null) return null;

      // handle PostgrestResponse-like object with .data
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

      // res is Map
      if (res is Map && res.containsKey('status')) {
        return res['status']?.toString();
      }

      // res is List
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

  Future<void> _handleNext() async {
    final phone = phoneCtrl.text.trim();
    if (!isPhoneValid) return;

    setState(() => loading = true);

    try {
      String? status;
      try {
        status = await _fetchOwnerStatusByPhone(phone);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengecek nomor: $e')),
        );
        return;
      }

      // tidak ditemukan => lanjut ke OTP
      if (status == null || status.trim().isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("OTP dikirim: $generatedOtp")),
        );
        Navigator.pushNamed(context, '/otp', arguments: phone);
        return;
      }

      final norm = status.trim().toLowerCase();

      // EXACT MATCH: hanya cocok jika persis 'pending', 'rejected', atau 'active'
      if (norm == 'pending') {
        // langsung ke status screen
        if (!mounted) return;
        if (useNamedRoute) {
          Navigator.pushNamed(context, '/status', arguments: phone);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => StatusScreen(phone: phone)),
          );
        }
        return;
      }

      if (norm == 'rejected') {
        if (!mounted) return;
        if (useNamedRoute) {
          Navigator.pushNamed(context, '/status', arguments: phone);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => StatusScreen(phone: phone)),
          );
        }
        return;
      }

      if (norm == 'active') {
        // sudah aktif => tampilkan pesan merah dan jangan lanjut
        setState(() {
          isRegisteredActive = true;
          _knownStatus = status;
        });
        return;
      }

      // fallback behaviour: jika status tak dikenali, kita anggap "sudah terdaftar"
      // dan tampilkan pesan. Kamu bisa ubah ini jika mau langsung ke StatusScreen.
      setState(() {
        isRegisteredActive = true;
        _knownStatus = status;
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFFB11F23);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          padding: const EdgeInsets.symmetric(vertical: 35),
          icon: const Icon(FontAwesomeIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Daftar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'poppins',
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Masukkan nomor handphone untuk aktivasi',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 15),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
              child: Column(
                children: [
                  TextField(
                    controller: phoneCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nomor Hp',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      suffixIcon: checking
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
                    ),
                    keyboardType: TextInputType.phone,
                    onChanged: (_) => setState(() {}),
                  ),

                  if (isRegisteredActive) ...[
                    const SizedBox(height: 10),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Nomor yang anda masukkan sudah terdaftar',
                        style: TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                    // optional: show DB status string for debugging (uncomment to see)
                    // if (_knownStatus != null) Text('Status dari DB: $_knownStatus'),
                  ] else
                    const SizedBox(height: 10),

                  const Spacer(),
                  PrimaryButton(
                    label: loading ? 'Memproses...' : "Selanjutnya",
                    onTap: (!isPhoneValid || isRegisteredActive || loading)
                        ? null
                        : _handleNext,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Sudah punya akun ? "),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/login');
                        },
                        child: const Text(
                          "Masuk Sekarang",
                          style: TextStyle(
                            color: Color(0xFFB11F23),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}