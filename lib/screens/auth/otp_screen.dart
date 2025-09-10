// sebelum menggunakan otp firebase auth by google
import 'package:ekatalog_etm/screens/auth/register_form.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _otpControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _textFocusNodes = List.generate(
    4,
    (index) => FocusNode(),
  );

  String message = "Masukkan kode OTP";
  Color outlineColor = Colors.grey;
  bool isSuccess = false;

  late AnimationController _animController;
  late Animation<double> _shakeAnimation;

  // Resend OTP state
  int _resendCooldown = 0; // seconds remaining for cooldown
  Timer? _resendTimer;
  final int _cooldownSec = 30;

  @override
  void initState() {
    super.initState();

    // init animation
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 12,
    ).chain(CurveTween(curve: Curves.elasticIn)).animate(_animController);

    // beri fokus ke kotak pertama setelah frame pertama
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _textFocusNodes[0].requestFocus();
    });

    // optionally start initial cooldown if OTP just dikirim by previous screen
    // startResendCooldown(); // uncomment if you want cooldown immediately
  }

  @override
  void dispose() {
    // bersihkan semua resources
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _textFocusNodes) {
      f.dispose();
    }
    _animController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _checkOtp() {
    String otp = _otpControllers.map((e) => e.text).join();
    if (_otpControllers.any((c) => c.text.isEmpty)) return;

    if (otp == "1234") {
      setState(() {
        outlineColor = const Color(0xFFFDD100);
        message = "OTP Berhasil!";
        isSuccess = true;
      });
      // optionally cancel resend timer if success
      _resendTimer?.cancel();
    } else {
      setState(() {
        outlineColor = const Color(0xFFB11F23);
        message = "OTP Salah!";
        isSuccess = false;
      });

      // mainkan animasi shake
      _animController.forward(from: 0);

      // bersihkan input setelah animasi
      Timer(const Duration(milliseconds: 420), () {
        if (!mounted) return;
        for (var c in _otpControllers) {
          c.clear();
        }
        // kembalikan fokus ke kotak pertama
        _textFocusNodes[0].requestFocus();
        setState(() {
          outlineColor = Colors.grey;
          message = "Masukkan kode OTP";
        });
      });
    }
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 60,
      height: 60,
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (event) {
          if (event.isKeyPressed(LogicalKeyboardKey.backspace)) {
            // kalau ada isi, hapus dan tetap di field ini
            if (_otpControllers[index].text.isNotEmpty) {
              setState(() {
                _otpControllers[index].clear();
              });
            } else if (index > 0) {
              // kalau kosong, pindah ke sebelumnya dan hapus di sana juga
              setState(() {
                _otpControllers[index - 1].clear();
              });
              _textFocusNodes[index - 1].requestFocus();
            }
          }
        },
        child: TextField(
          controller: _otpControllers[index],
          focusNode: _textFocusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          textInputAction: index == 3
              ? TextInputAction.done
              : TextInputAction.next,
          maxLength: 1,
          autofocus: index == 0,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            counterText: "",
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: outlineColor, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: outlineColor, width: 2),
            ),
          ),
          onChanged: (value) {
            if (value.length > 1) {
              // kalau user paste banyak angka → ambil angka pertama aja
              final first = value.characters.first;
              _otpControllers[index].text = first;
              _otpControllers[index].selection = const TextSelection.collapsed(
                offset: 1,
              );
            }

            if (value.isNotEmpty) {
              // otomatis pindah ke kanan
              if (index < _textFocusNodes.length - 1) {
                _textFocusNodes[index + 1].requestFocus();
              } else {
                // kalau semua sudah terisi → cek OTP
                if (_otpControllers.every((c) => c.text.isNotEmpty)) {
                  _checkOtp();
                }
              }
            }
          },
          onSubmitted: (_) {
            if (_otpControllers.every((c) => c.text.isNotEmpty)) {
              _checkOtp();
            }
          },
        ),
      ),
    );
  }

  // ---------------- Resend OTP logic ----------------

  Future<bool> _requestOtpFromServer() async {
    // TODO: ganti isi fungsi ini dengan pemanggilan API nyata untuk mengirim ulang OTP.
    // Contoh:
    // final res = await myApi.sendOtp(phone: widget.phone);
    // return res.success;

    // Saat ini kita hanya simulate delay dan return true
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendCooldown = _cooldownSec);

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendCooldown--;
        if (_resendCooldown <= 0) {
          timer.cancel();
          _resendCooldown = 0;
        }
      });
    });
  }

  Future<void> _onResendPressed() async {
    if (_resendCooldown > 0) return; // safety
    // optionally disable UI while requesting
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      const SnackBar(content: Text('Mengirim ulang kode...')),
    );

    try {
      final ok = await _requestOtpFromServer();
      if (!mounted) return;
      if (ok) {
        scaffold.hideCurrentSnackBar();
        scaffold.showSnackBar(
          const SnackBar(content: Text('Kode OTP telah dikirim ulang')),
        );
        _startResendCooldown();
        // clear any existing OTP input
        for (var c in _otpControllers) c.clear();
        _textFocusNodes[0].requestFocus();
      } else {
        scaffold.hideCurrentSnackBar();
        scaffold.showSnackBar(
          const SnackBar(
            content: Text('Gagal mengirim ulang kode. Coba lagi.'),
          ),
        );
      }
    } catch (e) {
      scaffold.hideCurrentSnackBar();
      scaffold.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  String _formatCooldown(int sec) {
    // format "00s" or "30s"
    return '${sec}s';
  }

  // ---------------- End resend logic ----------------

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
          // header merah
           Container(
            width: double.infinity,
            color: primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Verifikasi Nomor Handphone',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'poppins',
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Masukkan kode OTP',
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

          // konten utama
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // const Text(
                  //   "Masukkan kode OTP",
                  //   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  // ),
                  const SizedBox(height: 30),
                  AnimatedBuilder(
                    animation: _shakeAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(_shakeAnimation.value, 0),
                        child: child,
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        4,
                        (index) => _buildOtpBox(index),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // message
                  Text(
                    message,
                    style: TextStyle(
                      color: outlineColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // resend row: "Tidak menerima kode? Kirim Ulang Kode"
                  Align(
                    alignment: Alignment.centerLeft, // posisi ke kiri
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start, // isi column rata kiri
                      mainAxisSize: MainAxisSize
                          .min, // biar ukuran column ngikut kontennya
                      children: [
                        const Text(
                          'Tidak menerima kode?',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero, // hilangin padding bawaan
                            minimumSize: Size(0, 0), // biar nggak ada min size
                            foregroundColor: Color(0xFFB11F23), // warna teks
                            tapTargetSize: MaterialTapTargetSize
                                .shrinkWrap, // area klik pas konten
                            alignment:
                                Alignment.centerLeft, // teksnya rata kiri
                          ),
                          onPressed: (_resendCooldown == 0 && !isSuccess)
                              ? _onResendPressed
                              : null,
                          child: _resendCooldown == 0
                              ? const Text('Kirim Ulang Kode')
                              : Text(
                                  'Kirim Ulang (${_formatCooldown(_resendCooldown)})',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),
                  ElevatedButton(
                    onPressed: isSuccess
                        ? () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    RegistrationFormScreen(phone: widget.phone),
                              ),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFDD100),
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text(
                      "Selanjutnya",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
