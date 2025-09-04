// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../services/auth_service.dart';
// import '../widgets/primary_button.dart';

// class RegisterScreen extends StatefulWidget {
//   const RegisterScreen({super.key});

//   @override
//   State<RegisterScreen> createState() => _RegisterScreenState();
// }

// class _RegisterScreenState extends State<RegisterScreen> {
//   final TextEditingController phoneCtrl = TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     final auth = Provider.of<AuthService>(context);

    // return Scaffold(
    //   appBar: AppBar(
    //     backgroundColor: const Color(0xFFB11F23),
    //     elevation: 0,
    //     leading: IconButton(
    //       padding: const EdgeInsets.symmetric(vertical: 35),
    //       icon: const Icon(Icons.arrow_back, color: Colors.white),
    //       onPressed: () => Navigator.pop(context),
    //     ),
    //   ),
      // body: Column(
      //   crossAxisAlignment: CrossAxisAlignment.start,
      //   children: [
      //     // Judul & Subjudul
      //     Container(
      //       width: double.infinity,
      //       color: const Color(0xFFB11F23),
      //       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      //       child: Column(
      //         crossAxisAlignment: CrossAxisAlignment.start,
      //         children: const [
      //           Text(
      //             'Daftar',
      //             style: TextStyle(
      //               color: Colors.white,
      //               fontSize: 20,
      //               fontWeight: FontWeight.bold,
      //               fontFamily: 'poppins',
      //             ),
      //           ),
      //           SizedBox(height: 4),
      //           Text(
      //             'Masukkan nomor handphone untuk aktivasi',
      //             style: TextStyle(
      //               color: Colors.white,
      //               fontWeight: FontWeight.w500,
      //               fontSize: 14,
      //             ),
      //           ),
      //           SizedBox(height: 15),
      //         ],
      //       ),
      //     ),

//           // Input & OTP
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
//               child: Column(
//                 children: [
//                   TextField(
//                     controller: phoneCtrl,
//                     decoration: InputDecoration(
//                       labelText: 'Nomor Hp',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                     ),
//                     keyboardType: TextInputType.phone,
//                   ),

//                   const Spacer(), // Membuat kode otp ditengah layar

//                   // Kirim kode OTP
//                   Column(
//                     children: [
//                       const Text("Kirim kode OTP ?",
//                       style: TextStyle(
//                         fontFamily: 'poppins',
//                         fontWeight: FontWeight.w400,
//                         fontSize: 14,
//                       ),
//                       ),
//                       GestureDetector(
//                         onTap: () async {
//                           await auth.sendOtp(phoneCtrl.text.trim());
//                         },
//                         child: const Text(
//                           "Kode OTP",
//                           style: TextStyle(
//                             color: Color(0xFFB11F23),
//                             fontWeight: FontWeight.w500,
//                             fontFamily: 'poppins',
//                             fontSize: 14,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const Spacer(),

//                   // Tombol Selanjutnya
//                   PrimaryButton(
//                     label: auth.loading ? 'Loading...' : 'Selanjutnya',
//                     onTap: () async {
//                       await auth.register({'phone': phoneCtrl.text.trim()});
//                       Navigator.pushNamed(context, '/otp');
//                     },
//                   ),

                  // const SizedBox(height: 12),

                  // // Sudah punya akun
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.center,
                  //   children: [
                  //     const Text("Sudah punya akun ? "),
                  //     GestureDetector(
                  //       onTap: () {
                  //         Navigator.pushNamed(context, '/login');
                  //       },
                  //       child: const Text(
                  //         "Masuk Sekarang",
                  //         style: TextStyle(
                  //           color: Color(0xFFB11F23),
                  //           fontWeight: FontWeight.bold,
                  //         ),
                  //       ),
                  //     ),
                  //   ],
                  // ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import '../widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController phoneCtrl = TextEditingController();
  String generatedOtp = "1234"; // dummy otp

  bool get isPhoneValid {
    final phone = phoneCtrl.text.trim();
    return phone.isNotEmpty && phone.length >= 10 && phone.startsWith("08");
  }

  @override
  void dispose() {
    phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFB11F23),
        elevation: 0,
        leading: IconButton(
          padding: const EdgeInsets.symmetric(vertical: 35),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul & Subjudul
          Container(
            width: double.infinity,
            color: const Color(0xFFB11F23),
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
                    ),
                    keyboardType: TextInputType.phone,
                    onChanged: (_) => setState(() {}),
                  ),
                  const Spacer(),
                  PrimaryButton(
                    label: "Selanjutnya",
                    onTap: isPhoneValid
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("OTP dikirim: $generatedOtp")),
                            );
                            Navigator.pushNamed(
                              context,
                              '/otp',
                              arguments: phoneCtrl.text.trim(),
                            );
                          }
                        : null,
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
