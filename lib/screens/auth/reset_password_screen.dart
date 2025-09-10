// lib/screens/reset_password_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../widgets/primary_button.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String phone;
  const ResetPasswordScreen({super.key, required this.phone});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController passCtrl = TextEditingController();
  final TextEditingController confirmCtrl = TextEditingController();
  final Color primaryColor = const Color(0xFFB11F23);
  bool _obscure1 = true;
  bool _obscure2 = true;

  // Inline error + shake
  late AnimationController _animController;
  late Animation<double> _shakeAnimation;
  String? _errorMessage;
  bool _showError = false;

  @override
  void initState() {
    super.initState();

    // init animation controller untuk shake effect
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 12)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_animController);

    // jika phone kosong kemungkinan asal navigasi salah -> beri peringatan dan kembali
    if (widget.phone.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nomor telepon tidak ditemukan.')),
        );
        Navigator.pop(context);
      });
    }
  }

  @override
  void dispose() {
    passCtrl.dispose();
    confirmCtrl.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _showInlineError(String msg) {
    setState(() {
      _errorMessage = msg;
      _showError = true;
    });
    _animController.forward(from: 0.0);
  }

  void _clearInlineErrorIfAny() {
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
        _showError = false;
      });
    }
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
          padding: const EdgeInsets.symmetric(vertical: 20),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Masukkan Password Baru',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Buat password baru dan konfirmasi ulang',
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'Poppins'),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: passCtrl,
                      obscureText: _obscure1,
                      onChanged: (_) => _clearInlineErrorIfAny(),
                      decoration: InputDecoration(
                        labelText: 'Password baru',
                        suffixIcon: IconButton(
                          icon: Icon(_obscure1 ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscure1 = !_obscure1),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: primaryColor, width: 1.6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmCtrl,
                      obscureText: _obscure2,
                      onChanged: (_) => _clearInlineErrorIfAny(),
                      decoration: InputDecoration(
                        labelText: 'Konfirmasi password',
                        suffixIcon: IconButton(
                          icon: Icon(_obscure2 ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscure2 = !_obscure2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: primaryColor, width: 1.6),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Inline animated error (shake + fade) — mirip gaya di login screen
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
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _errorMessage ?? '',
                                  style: const TextStyle(
                                    color: Color(0xFFB11F23),
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ),
                    ),

                    const Spacer(),


                    PrimaryButton(
                      label: auth.loading ? 'Loading...' : 'Simpan password',
                      onTap: auth.loading
                          ? null
                          : () async {
                              // clear inline error first
                              _clearInlineErrorIfAny();

                              final p1 = passCtrl.text.trim();
                              final p2 = confirmCtrl.text.trim();

                              if (p1.isEmpty || p2.isEmpty) {
                                _showInlineError('Semua field wajib diisi');
                                return;
                              }
                              if (p1.length < 6) {
                                _showInlineError('Password minimal 6 karakter');
                                return;
                              }
                              if (p1 != p2) {
                                _showInlineError('Password tidak cocok');
                                return;
                              }

                              // Pastikan phone tersedia
                              final phone = widget.phone;
                              if (phone.isEmpty) {
                                _showInlineError('Nomor telepon tidak ditemukan');
                                return;
                              }

                              try {
                                final res = await auth.resetPassword(phone, p1);

                                if (res == null || res['ok'] == false) {
                                  _showInlineError(res?['message'] ?? 'Gagal mereset password');
                                  return;
                                }

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Password berhasil diubah. Silakan login.')),
                                );

                                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                              } catch (e, st) {
                                debugPrint('resetPassword error: $e\n$st');
                                _showInlineError('Terjadi kesalahan. Silakan coba lagi.');
                              }
                            },
                    ),

                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
