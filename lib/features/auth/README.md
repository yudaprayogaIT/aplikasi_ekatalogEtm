<!-- # feature: Auth

Deskripsi
---------
Feature `auth` menangani semua alur autentikasi dan pendaftaran pengguna:
- Login, logout
- Register (form & flows)
- OTP verification
- Forgot / Reset password
- Penyimpanan token / profile (via AuthService di /services)

Lokasi
------
`lib/features/auth/`

Struktur (ringkas)
------------------
- `ui/`
  - `login_screen.dart`
  - `register_screen.dart`
  - `register_form.dart`
  - `otp_screen.dart`
  - `forgot_password_screen.dart`
  - `reset_otp_screen.dart`
  - `reset_password_screen.dart`
- `data/` (opsional)
  - `auth_repository.dart` (interface ke Supabase)
- `providers/`
  - `auth_provider.dart` (ChangeNotifier / Bloc)
- `auth_pages.dart` (barrel export untuk import mudah)

Purpose / Contract
------------------
- `AuthService` (di `lib/services/auth_service.dart`) adalah single source of truth untuk auth-related calls.
- UI akan menggunakan `Provider.of<AuthService>(context)` atau `ChangeNotifierProvider(create: ...)`.
- `auth_provider` (opsional) mengekspor method:
  - `Future<Map> loginWithPhonePassword(String phone, String password)`
  - `Future<Map> findOwnerByPhone(String phone)`
  - `Future<void> sendOtp(String phone)` (demo)
  - `Future<Map> resetPassword(String phone, String newPassword)`

Routes
------
Tambahkan route berikut di `main.dart`:
```dart
'/login': (c) => const LoginScreen(),
'/register': (c) => const RegisterScreen(),
'/forgot': (c) => const ForgotPasswordScreen(),
'/reset': (c) => ResetOtpScreen(phone: argsPhone),
'/reset_password': (c) => ResetPasswordScreen(phone: argsPhone),
'/otp': (c) => OtpScreen(phone: argsPhone), -->
