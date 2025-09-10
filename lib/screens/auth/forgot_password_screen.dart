// lib/screens/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../widgets/primary_button.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../common/status_screen.dart';
import 'reset_otp_screen.dart'; // <-- import baru

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController phoneCtrl = TextEditingController();
  final Color primaryColor = const Color(0xFFB11F23);

  late AnimationController _animController;
  late Animation<double> _shakeAnimation;

  String? _errorMessage;
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 12,
    ).chain(CurveTween(curve: Curves.elasticIn)).animate(_animController);

    phoneCtrl.addListener(_clearErrorIfAny);
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
    phoneCtrl.dispose();
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
      body: Stack(
        children: [
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            width: double.infinity,
                            color: primaryColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Lupa Password',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'poppins',
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Masukkan nomor handphone Anda',
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

                          // Form
                          Expanded(
                            child: Padding(
                               padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 30,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextField(
                                    controller: phoneCtrl,
                                    keyboardType: TextInputType.phone,
                                    decoration: _inputDecoration('Nomor Hp')
                                  ),

                                  const SizedBox(height: 12),

                                  // Inline error
                                  AnimatedBuilder(
                                    animation: _animController,
                                    builder: (context, child) {
                                      final dx = _showError
                                          ? _shakeAnimation.value
                                          : 0.0;
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
                                            padding: const EdgeInsets.only(
                                              bottom: 12.0,
                                            ),
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                _errorMessage ?? '',
                                                style: const TextStyle(
                                                  color: Color(0xFFB11F23),
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                            ),
                                          ),
                                  ),

                                  const Spacer(),

                                  PrimaryButton(
  label: auth.loading ? 'Loading...' : 'Selanjutnya',
  onTap: auth.loading
      ? null
      : () async {
          final phone = phoneCtrl.text.trim();

          if (phone.isEmpty) {
            _showInlineError('Nomor hp wajib diisi');
            return;
          }

          try {
            final res = await auth.findOwnerByPhone(phone);
            debugPrint('findOwnerByPhone result: $res');

            if (res == null) {
              _showInlineError('Terjadi kesalahan. Coba lagi.');
              return;
            }

            if (res is Map && res['ok'] == false) {
              _showInlineError(res['message'] ?? 'Nomor tidak terdaftar');
              return;
            }

            final owner = (res is Map && res['owner'] is Map)
                ? Map<String, dynamic>.from(res['owner'])
                : <String, dynamic>{};

            final status = (owner['status'] ?? '').toString().toLowerCase();

            if (status == 'active' || status == 'approved') {
              // NAVIGASI LANGSUNG lewat konstruktor -> pasti ada widget.phone
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => ResetOtpScreen(phone: phone),
                ),
              );
            } else {
              // arahkan ke status screen (jaga agar null-safe)
              Navigator.pushReplacementNamed(
                context,
                StatusScreen.routeName,
                arguments: {'phone': phone},
              );
            }
          } catch (e, st) {
            debugPrint('Error in forgot password flow: $e\n$st');
            _showInlineError('Terjadi kesalahan internal. Silakan coba lagi.');
          }
        },
),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text("Belum punya akun ? "),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.pushNamed(
                                            context,
                                            '/register',
                                          );
                                        },
                                        child: const Text(
                                          "Daftar Sekarang",
                                          style: TextStyle(
                                            color: Color(0xFFB11F23),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
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
              },
            ),
          ),
        ],
      ),
    );
  }

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
      fillColor: Colors.white,
      enabledBorder: enabledBorder,
      focusedBorder: focusedBorder,
      errorBorder: enabledBorder,
      focusedErrorBorder: focusedBorder,
      suffixIcon: suffix,
    );
  }
}
