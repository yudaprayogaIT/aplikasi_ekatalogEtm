// lib/screens/login_screen.dart
import 'package:ekatalog_etm/screens/common/status_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../services/auth_service.dart';
import '../../widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  final Color primaryColor = const Color(0xFFB11F23);
  bool _obscurePassword = true;

  late AnimationController _animController;
  late Animation<double> _shakeAnimation;

  String? _errorMessage;
  bool _showError = false;

  // Biometric & secure storage
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _biometricAvailable = false;
  List<BiometricType> _availableBiometrics = [];
  bool _isAuthenticating = false; // for biometric in-progress

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
    passCtrl.addListener(_clearErrorIfAny);

    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      final bool canCheck = await _localAuth.canCheckBiometrics;
      List<BiometricType> available = [];
      if (canCheck) {
        available = await _localAuth.getAvailableBiometrics();
      }
      setState(() {
        _biometricAvailable = isDeviceSupported && (available.isNotEmpty);
        _availableBiometrics = available;
      });
    } catch (e) {
      setState(() {
        _biometricAvailable = false;
        _availableBiometrics = [];
      });
    }
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
    _animController.forward(from: 0.0);
  }

  // --- storage helpers ---
  Future<void> _saveCredentialsToSecureStorage({
    String? phone,
    String? password,
    String? token,
  }) async {
    if (phone != null) await _secureStorage.write(key: 'phone', value: phone);
    if (password != null)
      await _secureStorage.write(key: 'password', value: password);
    if (token != null)
      await _secureStorage.write(key: 'auth_token', value: token);
  }

  Future<void> _clearStoredCredentials() async {
    await _secureStorage.delete(key: 'auth_token');
    await _secureStorage.delete(key: 'phone');
    await _secureStorage.delete(key: 'password');
  }

  String? _extractTokenFromResponse(Map<String, dynamic> res) {
    try {
      if (res.containsKey('token') && res['token'] != null)
        return res['token'].toString();
      if (res.containsKey('access_token') && res['access_token'] != null)
        return res['access_token'].toString();
      if (res.containsKey('data') &&
          res['data'] is Map &&
          (res['data'] as Map).containsKey('token')) {
        return (res['data'] as Map)['token']?.toString();
      }
    } catch (_) {}
    return null;
  }

  // Offer to enable biometric only when account status active/approved
  Future<void> _offerEnableBiometricAfterLogin(
    String phone,
    String password,
    Map<String, dynamic> res,
  ) async {
    if (!_biometricAvailable) return;

    final enable = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aktifkan Face ID?'),
        content: const Text(
          'Aktifkan Face ID untuk login cepat di perangkat ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Ya'),
          ),
        ],
      ),
    );

    if (enable != true) return;

    try {
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason:
            'Konfirmasi untuk menyimpan login menggunakan biometrik',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (!didAuthenticate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Autentikasi biometrik tidak berhasil.'),
          ),
        );
        return;
      }

      final token = _extractTokenFromResponse(res);
      if (token != null) {
        await _saveCredentialsToSecureStorage(phone: phone, token: token);
        // do not save password if token exists
      } else {
        // fallback (kurang aman): simpan phone + password
        await _saveCredentialsToSecureStorage(phone: phone, password: password);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Catatan: token tidak ditemukan — menyimpan password secara lokal (kurang aman).',
            ),
          ),
        );
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Face ID diaktifkan.')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengaktifkan Face ID: $e')));
    }
  }

  // Biometric login flow: prefer phone+password fallback (safe regarding compile-time)
  Future<void> _authenticateWithBiometrics() async {
    final storedPhone = await _secureStorage.read(key: 'phone');
    final storedPass = await _secureStorage.read(key: 'password');
    final storedToken = await _secureStorage.read(key: 'auth_token');

    if ((storedPhone == null || storedPass == null) && storedToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tidak ada data login tersimpan. Silakan login sekali lalu aktifkan Face ID.',
          ),
        ),
      );
      return;
    }

    try {
      setState(() {
        _isAuthenticating = true;
      });

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Autentikasi menggunakan biometrik untuk login',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (!didAuthenticate) {
        return;
      }

      final auth = Provider.of<AuthService>(context, listen: false);
      Map<String, dynamic> res = {};

      // NOTE:
      // Ideal: jika AuthService mendukung loginWithToken, gunakan token.
      // Namun untuk kompatibilitas (agar compile aman), di sini kita gunakan
      // phone+password jika tersedia. Jika hanya token tersedia, tampilkan pesan.
      if (storedPhone != null && storedPass != null) {
        res = await auth.loginWithPhonePassword(storedPhone, storedPass);
      } else if (storedToken != null) {
        // Jika kamu punya auth.loginWithToken, ganti kode di bawah agar menggunakan token.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Terdapat token tersimpan tetapi AuthService belum mendukung login dengan token. Silakan login manual.',
            ),
          ),
        );
        return;
      }

      if (res['ok'] == false) {
        final msg = res['message'] ?? 'Gagal login';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
        return;
      }

      final status = (res['status'] ?? '').toString().toLowerCase();
      if (status == 'active' || status == 'approved') {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // akun tdk aktif -> hapus credential biometric & arahkan ke StatusScreen
        await _clearStoredCredentials();
        Navigator.pushReplacementNamed(
          context,
          StatusScreen.routeName,
          arguments: {'phone': storedPhone ?? ''},
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Autentikasi biometrik gagal: $e')),
      );
    } finally {
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    // show full overlay if auth.loading (from provider) or biometric authenticating
    final bool showOverlay = auth.loading || _isAuthenticating;

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
                                    decoration: _inputDecoration('Nomor Hp'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Poppins',
                                    ),
                                    keyboardType: TextInputType.phone,
                                  ),
                                  const SizedBox(height: 12),

                                  TextField(
                                    controller: passCtrl,
                                    decoration: _inputDecoration(
                                      'Password',
                                      suffix: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                      ),
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Poppins',
                                    ),
                                    obscureText: _obscurePassword,
                                  ),
                                  const SizedBox(height: 8),

                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Gunakan Face ID',
                                        style: TextStyle(fontSize: 13, color: Color(0xFFB11F23), fontFamily: 'Poppins' ),
                                      ),
                                      TextButton.icon(
                                        onPressed: _biometricAvailable
                                            ? () async {
                                                await _authenticateWithBiometrics();
                                              }
                                            : () {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Face ID / biometrik tidak tersedia di perangkat ini',
                                                    ),
                                                  ),
                                                );
                                              },
                                        icon: const Icon(
                                          Icons.fingerprint,
                                          size: 18,
                                        ),
                                        label: const Text(''),
                                      ),
                                    ],
                                  ),
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
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    _errorMessage ?? '',
                                                    style: const TextStyle(
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                  ),

                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.center,
                                    child: TextButton(
                                      onPressed: () => Navigator.pushNamed(
                                        context,
                                        '/forgot',
                                      ),
                                      child: const Text(
                                        'Lupa Password ?',
                                        style: TextStyle(
                                          color: Color(0xFFB11F23),
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const Spacer(),

                                  PrimaryButton(
                                    label: auth.loading
                                        ? 'Loading...'
                                        : 'Selanjutnya',
                                    onTap: auth.loading
                                        ? null
                                        : () async {
                                            final phone = phoneCtrl.text.trim();
                                            final pass = passCtrl.text;

                                            if (phone.isEmpty || pass.isEmpty) {
                                              _showInlineError(
                                                'Nomor dan password wajib diisi',
                                              );
                                              return;
                                            }

                                            final res = await auth
                                                .loginWithPhonePassword(
                                                  phone,
                                                  pass,
                                                );

                                            if (res['ok'] == false) {
                                              final msg =
                                                  res['message'] ??
                                                  'Gagal login';
                                              _showInlineError(msg);
                                              return;
                                            }

                                            final status = (res['status'] ?? '')
                                                .toString()
                                                .toLowerCase();

                                            if (status == 'active' ||
                                                status == 'approved') {
                                              // hanya tawarkan biometrik jika akun aktif
                                              await _offerEnableBiometricAfterLogin(
                                                phone,
                                                pass,
                                                res,
                                              );
                                              Navigator.pushReplacementNamed(
                                                context,
                                                '/home',
                                              );
                                            } else {
                                              // akun belum aktif / ditolak -> jangan simpan biometrik
                                              Navigator.pushReplacementNamed(
                                                context,
                                                StatusScreen.routeName,
                                                arguments: {'phone': phone},
                                              );
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

          // overlay loading (disables UI while waiting)
          if (showOverlay)
            Positioned.fill(
              child: Container(
                color: Colors.black38,
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
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
      fillColor: Colors.white,
      enabledBorder: enabledBorder,
      focusedBorder: focusedBorder,
      errorBorder: enabledBorder,
      focusedErrorBorder: focusedBorder,
      suffixIcon: suffix,
    );
  }
}
