// lib/screens/login_screen.dart
import 'package:ekatalog_etm/screens/status_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../services/auth_service.dart';
import '../widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  final Color primaryColor = const Color(0xFFB11F23);
  bool _obscurePassword = true;

  late AnimationController _animController;
  late Animation<double> _shakeAnimation;

  String? _errorMessage;
  bool _showError = false;

  @override
  void initState() {
    super.initState();

    // inisialisasi animasi shake (mirip OtpScreen)
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _shakeAnimation = Tween<double>(begin: 0, end: 12).chain(CurveTween(curve: Curves.elasticIn)).animate(_animController);

    // clear error ketika user mengetik ulang
    phoneCtrl.addListener(_clearErrorIfAny);
    passCtrl.addListener(_clearErrorIfAny);
  }

  void _clearErrorIfAny() {
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
        _showError = false;
      });
    }
  }

  @override
  void dispose() {
    phoneCtrl.removeListener(_clearErrorIfAny);
    passCtrl.removeListener(_clearErrorIfAny);
    phoneCtrl.dispose();
    passCtrl.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _showInlineError(String msg) {
    setState(() {
      _errorMessage = msg;
      _showError = true;
    });
    // jalankan animasi shake
    _animController.forward(from: 0.0);
  }

  // Reusable input decoration mirip style di register_form
  InputDecoration _inputDecoration(String label, {Widget? suffix}) {
    final borderRadius = BorderRadius.circular(8.0);
    final enabledBorder = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: Colors.grey.shade400, width: 1.2),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: primaryColor, width: 1.8),
    );
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontWeight: FontWeight.w500),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      filled: true,
      fillColor: Colors.white, // kalau register pakai putih; ubah kalau mau transparan
      enabledBorder: enabledBorder,
      focusedBorder: focusedBorder,
      errorBorder: enabledBorder,
      focusedErrorBorder: focusedBorder,
      suffixIcon: suffix,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          padding: const EdgeInsets.symmetric(vertical: 35),
          icon: const Icon(FontAwesomeIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header merah (judul + subjudul)
                    Container(
                      width: double.infinity,
                      color: primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Masuk',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'poppins',
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Masukkan nomor dan password Anda',
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

                    // Flexible area (form + button tetap di bawah)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Nomor HP dengan style register_form
                            TextField(
                              controller: phoneCtrl,
                              decoration: _inputDecoration('Nomor Hp'),
                              style: const TextStyle(fontWeight: FontWeight.w500, fontFamily: 'Poppins'),
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 12),

                            // Password dengan style register_form + suffix icon show/hide
                            TextField(
                              controller: passCtrl,
                              decoration: _inputDecoration(
                                'Password',
                                suffix: IconButton(
                                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              style: const TextStyle(fontWeight: FontWeight.w500, fontFamily: 'Poppins'),
                              obscureText: _obscurePassword,
                            ),
                            const SizedBox(height: 8),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Gunakan Face ID', style: TextStyle(fontSize: 13)),
                                TextButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Face ID belum diaktifkan')));
                                  },
                                  icon: const Icon(Icons.fingerprint, size: 18),
                                  label: const Text(''),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.center,
                              child: TextButton(
                                onPressed: () => Navigator.pushNamed(context, '/forgot'),
                                child: const Text('Lupa password ?'),
                              ),
                            ),

                            const Spacer(),

                            // Inline error: hanya teks (seperti OtpScreen) dengan efek shake
                            AnimatedBuilder(
                              animation: _animController,
                              builder: (context, child) {
                                final dx = _showError ? _shakeAnimation.value : 0.0;
                                return Opacity(
                                  opacity: _showError ? 1.0 : 0.0,
                                  child: Transform.translate(
                                    offset: Offset(dx, 0),
                                    child: child,
                                  ),
                                );
                              },
                              child: _errorMessage == null
                                  ? const SizedBox.shrink()
                                  : Padding(
                                      padding: const EdgeInsets.only(bottom: 12.0),
                                      child: Text(
                                        _errorMessage ?? '',
                                        style: const TextStyle(
                                          color: Color(0xFFB11F23), // merah seperti tema Anda
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                            ),

                            PrimaryButton(
                              label: auth.loading ? 'Loading...' : 'Selanjutnya',
                              onTap: auth.loading
                                  ? null
                                  : () async {
                                      final phone = phoneCtrl.text.trim();
                                      final pass = passCtrl.text;

                                      final res = await auth.loginWithPhonePassword(phone, pass);

                                      if (res['ok'] == false) {
                                        final msg = res['message'] ?? 'Gagal login';
                                        _showInlineError(msg);
                                        return;
                                      }

                                      final status = (res['status'] ?? '').toString().toLowerCase();
                                      if (status == 'active' || status == 'approved') {
                                        Navigator.pushReplacementNamed(context, '/home');
                                      } else {
                                        Navigator.pushReplacementNamed(
                                          context,
                                          StatusScreen.routeName,
                                          arguments: {'phone': phone},
                                        );
                                      }
                                    },
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fitur daftar belum disediakan di demo')));
                              },
                              child: const Text('Belum punya akun? Daftar Sekarang'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
