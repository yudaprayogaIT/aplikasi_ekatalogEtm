import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController phoneCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Lupa Password')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text('Masukkan nomor HP yang terdaftar untuk mereset password'),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Nomor Hp'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: auth.loading
                  ? null
                  : () async {
                      final phone = phoneCtrl.text.trim();
                      // Panggil nama method yang ada di AuthService
                      final res = await auth.findOwnerByPhone(phone);
                      if (res['ok'] == false) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Tidak ditemukan')));
                        return;
                      }
                      // lanjut ke halaman reset (demo)
                      Navigator.pushNamed(context, '/reset', arguments: {'phone': phone});
                    },
              child: auth.loading ? const Text('Loading...') : const Text('Lanjutkan'),
            )
          ],
        ),
      ),
    );
  }
}
