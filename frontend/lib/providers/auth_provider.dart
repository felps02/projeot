import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storage = StorageService();

  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null && _token != null;
  bool get isLeader => _user?.isLider ?? false;

  Future<bool> checkAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      _token = await _storage.getToken();
      _user = await _storage.getUser();

      if (_token != null && _user != null) {
        final freshUser = await _authService.getMe();
        if (freshUser != null) {
          _user = freshUser;
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (_) {
      // Token might be expired
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.login(email, password);

    if (result.success && result.user != null) {
      _user = result.user;
      _token = await _storage.getToken();
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _errorMessage = result.message;
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register({
    required String nome,
    required String email,
    required String password,
    required String cargo,
    String setor = '',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.register(
      nome: nome,
      email: email,
      password: password,
      cargo: cargo,
      setor: setor,
    );

    if (result.success && result.user != null) {
      _user = result.user;
      _token = await _storage.getToken();
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _errorMessage = result.message;
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _token = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
