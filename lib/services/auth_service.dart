// lib/services/auth_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends ChangeNotifier {
  final SupabaseClient supabase = Supabase.instance.client;

  bool _loading = false;
  bool get loading => _loading;
  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  // owner / company / branch state (diisi setelah login)
  Map<String, dynamic>? _owner;
  Map<String, dynamic>? _company;
  Map<String, dynamic>? _branch;

  Map<String, dynamic>? get owner => _owner;
  Map<String, dynamic>? get company => _company;
  Map<String, dynamic>? get branch => _branch;
  bool get isAuthenticated => _owner != null;

  // ---------- New helper getters ----------
  /// Nama owner (contoh: "Yanto Simatupang")
  String? get ownerName => _owner?['owner_name']?.toString();

  /// Nama company (contoh: "Ekatunggal Tunas Mandiri")
  String? get companyName => _company?['company_name']?.toString();

  /// Nama branch jika ada
  String? get branchName => _branch?['branch_name']?.toString() ?? _company?['branch_name']?.toString();

  /// Daerah / region dari branch
  String? get daerah => _branch?['daerah']?.toString();

    /// Nomor Telepon owner
  String? get phoneNumber => _owner?['phone_number']?.toString();

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
  /// Setelah berhasil, ambil kemungkinan `company` (cari berdasarkan phone_number)
  /// lalu ambil `branch` berdasarkan company.branch_id (jika ada).
  Future<Map<String, dynamic>> loginWithPhonePassword(String phone, String password) async {
    if (phone.isEmpty || password.isEmpty) {
      return {'ok': false, 'message': 'Nomor dan password harus diisi.'};
    }

    _setLoading(true);
    try {
      final ownerResp = await supabase
          .from('owners')
          .select('id, owner_name, phone_number, password, status')
          .eq('phone_number', phone)
          .maybeSingle();

      if (ownerResp == null) {
        return {'ok': false, 'message': 'Akun tidak ditemukan.'};
      }

      final owner = Map<String, dynamic>.from(ownerResp as Map);
      final storedPassword = (owner['password'] ?? '').toString();

      if (storedPassword.isEmpty) {
        return {'ok': false, 'message': 'Password belum diset. Silakan reset password.'};
      }

      if (storedPassword != password) {
        return {'ok': false, 'message': 'Password salah.'};
      }

      final status = (owner['status'] ?? '').toString().toLowerCase();

      // set local state owner
      _owner = owner;
      _company = null;
      _branch = null;
      notifyListeners();

      // try to find company by phone_number (if you use another FK, ganti query ini)
      try {
        final comp = await supabase
            .from('companies')
            .select('id, company_name, branch_id, branch_name, phone_number, address')
            .eq('phone_number', phone)
            .maybeSingle();

        if (comp != null) {
          _company = Map<String, dynamic>.from(comp as Map);
          notifyListeners();

          // if company has branch_id -> fetch branch
          final branchId = _company?['branch_id'];
          if (branchId != null) {
            try {
              final br = await supabase
                  .from('branch')
                  .select('id, branch_name, address, daerah, pulau, phone_number, is_public')
                  .eq('id', branchId)
                  .maybeSingle();
              if (br != null) {
                _branch = Map<String, dynamic>.from(br as Map);
                notifyListeners();
              }
            } catch (e) {
              debugPrint('fetch branch error: $e');
            }
          }
        } else {
          // fallback: maybe company row exists but phone_number blank -> try company where id == owner.id? (tweak later)
        }
      } catch (e) {
        debugPrint('fetch company error: $e');
      }

      return {'ok': true, 'owner': owner, 'status': status};
    } catch (e) {
      debugPrint('login error: $e');
      return {'ok': false, 'message': 'Terjadi error: ${e.toString()}'};
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _owner = null;
    _company = null;
    _branch = null;
    notifyListeners();
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

  Future<Map<String, dynamic>> resetPassword(String phone, String newPassword) async {
    if (phone.isEmpty || newPassword.isEmpty) return {'ok': false, 'message': 'Data tidak lengkap.'};
    _setLoading(true);
    try {
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
      debugPrint('resetPassword error: $e');
      return {'ok': false, 'message': 'Terjadi error: ${e.toString()}'};
    } finally {
      _setLoading(false);
    }
  }
}
