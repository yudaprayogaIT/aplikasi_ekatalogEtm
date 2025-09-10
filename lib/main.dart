// // main.dart
// import 'package:ekatalog_etm/screens/home_screen.dart';
// import 'package:ekatalog_etm/screens/register_form.dart';
// import 'package:ekatalog_etm/screens/status_screen.dart';
// import 'package:ekatalog_etm/screens/welcome_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// import 'services/auth_service.dart';
// import 'screens/splash_screen.dart';
// import 'screens/login_screen.dart';
// import 'screens/register_screen.dart';
// import 'screens/otp_screen.dart';

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // 🔑 Supabase init
//   await Supabase.initialize(
//     url: 'https://fzvezclybehnerqkkvqy.supabase.co',
//     anonKey:
//         'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ6dmV6Y2x5YmVobmVycWtrdnF5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY4ODUyNDEsImV4cCI6MjA3MjQ2MTI0MX0.dLvCVkRVbCToDKAh6lx_fI_EXY6HBPY14CfQ2yVspS0',
//   );

//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider(
//       create: (_) => AuthService(),
//       child: MaterialApp(
//         title: 'ETM Starter',
//         debugShowCheckedModeBanner: false,
//         theme: ThemeData(
//           primaryColor: const Color(0xFFb71c1c),
//           scaffoldBackgroundColor: Colors.white,
//           useMaterial3: false,
//         ),
//         initialRoute: '/welcome_screen',
//         routes: {
//           // '/': (_) => const SplashScreen(),
//           '/': (c) => const WelcomeScreen(),
//           StatusScreen.routeName: (c) => StatusScreen(
//             phone: '<phone>',
//           ), // prefer pass phone dynamically with Navigator.pushNamed
//           // '/home': (_) => const HomeScreen(),
//           '/welcome_screen': (_) => const WelcomeScreen(),
//           '/login': (c) => const LoginScreen(),
//           '/register': (_) => const RegisterScreen(),
//           '/otp': (context) {
//             final phone = ModalRoute.of(context)!.settings.arguments as String;
//             return OtpScreen(phone: phone);
//           },
//           '/register-form': (context) {
//             final phone = ModalRoute.of(context)!.settings.arguments as String;
//             return RegistrationFormScreen(phone: phone);
//           },
//         },
//       ),
//     );
//   }
// }

// main.dart
import 'package:ekatalog_etm/screens/home_screen.dart';
import 'package:ekatalog_etm/screens/register_form.dart';
import 'package:ekatalog_etm/screens/status_screen.dart';
import 'package:ekatalog_etm/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'services/auth_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/otp_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/reset_otp_screen.dart';
import 'screens/reset_password_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔑 Supabase init (tetap gunakan yang sudah Anda punya)
  await Supabase.initialize(
    url: 'https://fzvezclybehnerqkkvqy.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ6dmV6Y2x5YmVobmVycWtrdnF5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY4ODUyNDEsImV4cCI6MjA3MjQ2MTI0MX0.dLvCVkRVbCToDKAh6lx_fI_EXY6HBPY14CfQ2yVspS0',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: MaterialApp(
        title: 'ETM Starter',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFFb71c1c),
          scaffoldBackgroundColor: Colors.white,
          useMaterial3: false,
        ),
        initialRoute: '/welcome_screen',
routes: {
  '/': (c) => const WelcomeScreen(),

  // StatusScreen (menerima phone)
  StatusScreen.routeName: (c) {
    final args = ModalRoute.of(c)?.settings.arguments;
    String phone = '';
    if (args is String) phone = args;
    if (args is Map<String, dynamic> && args.containsKey('phone')) {
      phone = args['phone']?.toString() ?? '';
    }
    return StatusScreen(phone: phone);
  },

  '/welcome_screen': (c) => const WelcomeScreen(),
  '/login': (c) => const LoginScreen(),
  '/forgot': (c) => const ForgotPasswordScreen(),

  // Reset OTP (ambil argument dengan aman)
  '/reset': (c) {
    final args = ModalRoute.of(c)?.settings.arguments;
    String phone = '';
    if (args is String) phone = args;
    if (args is Map<String, dynamic> && args.containsKey('phone')) {
      phone = args['phone']?.toString() ?? '';
    }
    return ResetOtpScreen(phone: phone);
  },

  // Reset Password (harus kirim phone juga)
  '/reset_password': (c) {
    final args = ModalRoute.of(c)?.settings.arguments;
    String phone = '';
    if (args is String) phone = args;
    if (args is Map<String, dynamic> && args.containsKey('phone')) {
      phone = args['phone']?.toString() ?? '';
    }
    return ResetPasswordScreen(phone: phone);
  },

  '/register': (c) => const RegisterScreen(),

  // OTP screen (menerima phone)
  '/otp': (c) {
    final args = ModalRoute.of(c)?.settings.arguments;
    String phone = '';
    if (args is String) phone = args;
    if (args is Map<String, dynamic> && args.containsKey('phone')) {
      phone = args['phone']?.toString() ?? '';
    }
    return OtpScreen(phone: phone);
  },

  // Registration form (menerima phone)
  '/register-form': (c) {
    final args = ModalRoute.of(c)?.settings.arguments;
    String phone = '';
    if (args is String) phone = args;
    if (args is Map<String, dynamic> && args.containsKey('phone')) {
      phone = args['phone']?.toString() ?? '';
    }
    return RegistrationFormScreen(phone: phone);
  },

  // home
  '/home': (c) => const HomeScreen(),
},
      ),
    );
  }
}
