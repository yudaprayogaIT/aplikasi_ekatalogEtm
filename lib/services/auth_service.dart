// // lib/services/auth_service.dart
// import 'dart:async';
// import 'package:flutter/material.dart';
// import '../models/user.dart';

// class AuthService extends ChangeNotifier {
//   // Simulasi storage sederhana
//   final Map<String, UserModel> _users = {};
//   String? _lastOtp;
//   String? _pendingPhone;

//   bool _loading = false;
//   bool get loading => _loading;

//   void _setLoading(bool v) {
//     _loading = v;
//     notifyListeners();
//   }

//   Future<void> sendOtp(String phone) async {
//     _setLoading(true);
//     await Future.delayed(const Duration(seconds: 1));
//     _lastOtp = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000))
//         .toString();
//     _pendingPhone = phone;
//     // In real app: call server to send OTP
//     debugPrint('DEBUG OTP: $_lastOtp');
//     _setLoading(false);
//   }

//   Future<bool> verifyOtp(String code) async {
//     _setLoading(true);
//     await Future.delayed(const Duration(milliseconds: 800));
//     final ok = code == _lastOtp;
//     _setLoading(false);
//     return ok;
//   }

//   Future<bool> register(Map<String, dynamic> payload) async {
//     // payload contains phone & name etc.
//     _setLoading(true);
//     await Future.delayed(const Duration(seconds: 1));
//     final id = DateTime.now().millisecondsSinceEpoch.toString();
//     final user = UserModel(
//       id: id,
//       fullName: payload['fullName'] ?? 'User',
//       phone: payload['phone'] ?? '',
//     );
//     // by default set to pending
//     _users[user.phone] = user;
//     _setLoading(false);
//     return true;
//   }

//   Future<bool> login(String phone, String password) async {
//     _setLoading(true);
//     await Future.delayed(const Duration(seconds: 1));
//     // Dummy: password not checked
//     final exists = _users.containsKey(phone);
//     _setLoading(false);
//     return exists;
//   }

//   UserModel? getUser(String phone) => _users[phone];
// }

// lib/services/auth_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends ChangeNotifier {
  final supabase = Supabase.instance.client;

  bool _loading = false;
  bool get loading => _loading;

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  // OTP demo (tidak mengirim SMS, hanya simpan untuk verifikasi lokal)
  String? _lastOtp;
  String? _pendingPhone;

  Future<void> sendOtp(String phone) async {
    _setLoading(true);
    await Future.delayed(const Duration(milliseconds: 800));
    _lastOtp = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();
    _pendingPhone = phone;
    debugPrint('DEBUG OTP: $_lastOtp for $phone');
    _setLoading(false);
  }

  Future<bool> verifyOtp(String code) async {
    _setLoading(true);
    await Future.delayed(const Duration(milliseconds: 600));
    final ok = code == _lastOtp;
    _setLoading(false);
    return ok;
  }

  /// Login: cek tabel `owners` berdasarkan `phone_number`.
  /// Mengembalikan Map:
  /// { ok: bool, message?: String, owner?: Map, status?: String }
  Future<Map<String, dynamic>> loginWithPhonePassword(String phone, String password) async {
    if (phone.isEmpty || password.isEmpty) {
      return {'ok': false, 'message': 'Nomor dan password harus diisi.'};
    }

    _setLoading(true);
    try {
      // Ambil kolom yang memang ada di tabel owners: id, owner_name, phone_number, password, status
      final ownerResp = await supabase
          .from('owners')
          .select('id, owner_name, phone_number, password, status')
          .eq('phone_number', phone)
          .maybeSingle();

      if (ownerResp == null) {
        return {'ok': false, 'message': 'Akun tidak ditemukan.'};
      }

      final owner = Map<String, dynamic>.from(ownerResp as Map);

      // DEMO: password compare plaintext (TIDAK aman)
      final storedPassword = (owner['password'] ?? '').toString();
      if (storedPassword.isEmpty) {
        return {'ok': false, 'message': 'Password belum diset. Silakan reset password.'};
      }

      if (storedPassword != password) {
        return {'ok': false, 'message': 'Password salah.'};
      }

      final status = (owner['status'] ?? '').toString().toLowerCase();

      // NOTE: tidak lagi mencoba mengambil company karena table owners tidak punya company_id
      return {'ok': true, 'owner': owner, 'status': status};
    } catch (e) {
      debugPrint('login error: $e');
      return {'ok': false, 'message': 'Terjadi error: ${e.toString()}'};
    } finally {
      _setLoading(false);
    }
  }

  /// untuk forgot password: cek owner by phone
  Future<Map<String, dynamic>> findOwnerByPhone(String phone) async {
    if (phone.isEmpty) return {'ok': false, 'message': 'Masukkan nomor.'};
    _setLoading(true);
    try {
      final resp = await supabase
          .from('owners')
          .select('id, owner_name, phone_number, status')
          .eq('phone_number', phone)
          .maybeSingle();
      if (resp == null) return {'ok': false, 'message': 'Nomor tidak terdaftar.'};
      return {'ok': true, 'owner': Map<String, dynamic>.from(resp as Map)};
    } catch (e) {
      debugPrint('findOwnerByPhone error: $e');
      return {'ok': false, 'message': 'Terjadi error: ${e.toString()}'};
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> resetOwnerPassword(String phone, String newPassword) async {
    if (phone.isEmpty || newPassword.isEmpty) return {'ok': false, 'message': 'Data tidak lengkap.'};
    _setLoading(true);
    try {
      // lakukan update dan minta row yang di-update kembali
      final updated = await supabase
          .from('owners')
          .update({'password': newPassword})
          .eq('phone_number', phone)
          .select('id, owner_name, phone_number')
          .maybeSingle();

      if (updated == null) {
        return {'ok': false, 'message': 'Gagal mengubah password — record tidak ditemukan.'};
      }

      return {'ok': true, 'message': 'Password berhasil diubah.'};
    } catch (e) {
      debugPrint('resetOwnerPassword error: $e');
      return {'ok': false, 'message': 'Terjadi error: ${e.toString()}'};
    } finally {
      _setLoading(false);
    }
  }
}
