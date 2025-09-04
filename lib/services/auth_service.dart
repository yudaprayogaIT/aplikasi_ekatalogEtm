import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  // Simulasi storage sederhana
  final Map<String, UserModel> _users = {};
  String? _lastOtp;
  String? _pendingPhone;

  bool _loading = false;
  bool get loading => _loading;

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  Future<void> sendOtp(String phone) async {
    _setLoading(true);
    await Future.delayed(const Duration(seconds: 1));
    _lastOtp = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000))
        .toString();
    _pendingPhone = phone;
    // In real app: call server to send OTP
    debugPrint('DEBUG OTP: $_lastOtp');
    _setLoading(false);
  }

  Future<bool> verifyOtp(String code) async {
    _setLoading(true);
    await Future.delayed(const Duration(milliseconds: 800));
    final ok = code == _lastOtp;
    _setLoading(false);
    return ok;
  }

  Future<bool> register(Map<String, dynamic> payload) async {
    // payload contains phone & name etc.
    _setLoading(true);
    await Future.delayed(const Duration(seconds: 1));
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final user = UserModel(
      id: id,
      fullName: payload['fullName'] ?? 'User',
      phone: payload['phone'] ?? '',
    );
    // by default set to pending
    _users[user.phone] = user;
    _setLoading(false);
    return true;
  }

  Future<bool> login(String phone, String password) async {
    _setLoading(true);
    await Future.delayed(const Duration(seconds: 1));
    // Dummy: password not checked
    final exists = _users.containsKey(phone);
    _setLoading(false);
    return exists;
  }

  UserModel? getUser(String phone) => _users[phone];
}
