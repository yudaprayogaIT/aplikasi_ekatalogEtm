// import 'package:ekatalog_etm/screens/register_form.dart';
// import 'package:flutter/material.dart';
// import 'dart:async';
// import 'package:flutter/services.dart';

// class OtpScreen extends StatefulWidget {
//   const OtpScreen({super.key});

//   @override
//   State<OtpScreen> createState() => _OtpScreenState();
// }

// class _OtpScreenState extends State<OtpScreen>
//     with SingleTickerProviderStateMixin {
//   final List<TextEditingController> _otpControllers =
//       List.generate(4, (index) => TextEditingController());
//   final List<FocusNode> _textFocusNodes =
//       List.generate(4, (index) => FocusNode());
//   final FocusNode _keyboardFocus = FocusNode(); // untuk backspace

//   String message = "Tidak dapat kode? Kirim ulang kode";
//   Color outlineColor = Colors.grey;
//   bool isSuccess = false;

//   late AnimationController _animController;
//   late Animation<double> _shakeAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _animController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 400),
//     );

//     _shakeAnimation = Tween<double>(begin: 0, end: 16)
//         .chain(CurveTween(curve: Curves.elasticIn))
//         .animate(_animController);

//     _keyboardFocus.requestFocus();
//   }

//   @override
//   void dispose() {
//     for (var c in _otpControllers) {
//       c.dispose();
//     }
//     for (var f in _textFocusNodes) {
//       f.dispose();
//     }
//     _keyboardFocus.dispose();
//     _animController.dispose();
//     super.dispose();
//   }

//   void _checkOtp() {
//     String otp = _otpControllers.map((e) => e.text).join();
//     if (_otpControllers.any((c) => c.text.isEmpty)) return; // pastikan semua isi

//     if (otp == "1234") {
//       setState(() {
//         outlineColor = Colors.yellow.shade700;
//         message = "Berhasil!";
//         isSuccess = true;
//       });
//     } else {
//       setState(() {
//         outlineColor = Colors.red;
//         message = "OTP Salah! Kirim Ulang Kode";
//         isSuccess = false;
//       });
//       _animController.forward(from: 0);

//       Timer(const Duration(milliseconds: 400), () {
//         for (var c in _otpControllers) {
//           c.clear();
//         }
//         _textFocusNodes[0].requestFocus();
//       });
//     }
//   }

//   Widget _buildOtpBox(int index) {
//     return SizedBox(
//       width: 60,
//       height: 60,
//       child: TextField(
//         controller: _otpControllers[index],
//         focusNode: _textFocusNodes[index],
//         textAlign: TextAlign.center,
//         keyboardType: TextInputType.number,
//         maxLength: 1,
//         inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//         decoration: InputDecoration(
//           counterText: "",
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(8),
//             borderSide: BorderSide(color: outlineColor, width: 2),
//           ),
//           enabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(8),
//             borderSide: BorderSide(color: outlineColor, width: 2),
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(8),
//             borderSide: BorderSide(color: outlineColor, width: 2),
//           ),
//         ),
//         onChanged: (value) {
//           // Handle paste (kalau user paste string panjang)
//           if (value.length > 1) {
//             _handlePaste(value);
//             return;
//           }

//           // Auto move forward
//           if (value.isNotEmpty && index < 3) {
//             _textFocusNodes[index + 1].requestFocus();
//           }

//           // Cek OTP kalau semua sudah terisi
//           if (_otpControllers.every((c) => c.text.isNotEmpty)) {
//             _checkOtp();
//           }
//         },
//       ),
//     );
//   }

//   void _handlePaste(String pasteValue) {
//     final digits = pasteValue.replaceAll(RegExp(r'\D'), ''); // ambil hanya angka
//     for (int i = 0; i < 4; i++) {
//       _otpControllers[i].text = i < digits.length ? digits[i] : '';
//     }
//     // fokus ke akhir
//     if (digits.length < 4) {
//       _textFocusNodes[digits.length].requestFocus();
//     } else {
//       _checkOtp();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Verifikasi OTP")),
//       body: RawKeyboardListener(
//         focusNode: _keyboardFocus,
//         onKey: (event) {
//           if (event is RawKeyDownEvent &&
//               event.logicalKey == LogicalKeyboardKey.backspace) {
//             int currentIndex =
//                 _textFocusNodes.indexWhere((f) => f.hasFocus);

//             if (currentIndex > 0 &&
//                 _otpControllers[currentIndex].text.isEmpty) {
//               _textFocusNodes[currentIndex - 1].requestFocus();
//               _otpControllers[currentIndex - 1].clear();
//             }
//           }
//         },
//         child: Padding(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             children: [
//               const Text(
//                 "Masukkan kode OTP",
//                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 30),
//               AnimatedBuilder(
//                 animation: _shakeAnimation,
//                 builder: (context, child) {
//                   return Transform.translate(
//                     offset: Offset(_shakeAnimation.value, 0),
//                     child: child,
//                   );
//                 },
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: List.generate(4, (index) => _buildOtpBox(index)),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               Text(
//                 message,
//                 style: TextStyle(
//                   color: outlineColor,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const Spacer(),
//               ElevatedButton(
//                 onPressed: isSuccess
//                     ? () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) =>
//                                 const RegistrationFormScreen(),
//                           ),
//                         );
//                       }
//                     : null,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.yellow.shade700,
//                   foregroundColor: Colors.black,
//                   minimumSize: const Size(double.infinity, 50),
//                 ),
//                 child: const Text("Selanjutnya"),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:ekatalog_etm/screens/register_form.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _otpControllers =
      List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _textFocusNodes =
      List.generate(4, (index) => FocusNode());

  String message = "Masukkan kode OTP";
  Color outlineColor = Colors.grey;
  bool isSuccess = false;

  late AnimationController _animController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 16)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_animController);
  }

  void _checkOtp() {
    String otp = _otpControllers.map((e) => e.text).join();
    if (_otpControllers.any((c) => c.text.isEmpty)) return;

    if (otp == "1234") {
      setState(() {
        outlineColor = Colors.green;
        message = "OTP Berhasil!";
        isSuccess = true;
      });
    } else {
      setState(() {
        outlineColor = Colors.red;
        message = "OTP Salah!";
        isSuccess = false;
      });
      _animController.forward(from: 0);

      Timer(const Duration(milliseconds: 400), () {
        for (var c in _otpControllers) {
          c.clear();
        }
        _textFocusNodes[0].requestFocus();
      });
    }
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 60,
      height: 60,
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _textFocusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: "",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: outlineColor, width: 2),
          ),
        ),
        onChanged: (value) {
          if (value.length > 1) return;

          if (value.isNotEmpty && index < 3) {
            _textFocusNodes[index + 1].requestFocus();
          }

          if (_otpControllers.every((c) => c.text.isNotEmpty)) {
            _checkOtp();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verifikasi OTP")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Masukkan kode OTP",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
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
                children: List.generate(4, (index) => _buildOtpBox(index)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: TextStyle(
                color: outlineColor,
                fontWeight: FontWeight.bold,
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
                backgroundColor: Colors.yellow.shade700,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Selanjutnya"),
            ),
          ],
        ),
      ),
    );
  }
}
