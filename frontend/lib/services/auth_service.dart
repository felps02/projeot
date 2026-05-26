import '../config/api_config.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  Future<({bool success, User? user, String? message})> login(
      String email, String password) async {
    final response = await _api.post(
      ApiConfig.login,
      body: {'email': email, 'senha': password},
    );

    if (response.success && response.data != null) {
      final token = response.data['token'] ?? '';
      final userData = response.data['usuario'] ?? response.data;
      final user = User.fromJson(userData);

      await _storage.saveToken(token);
      await _storage.saveUser(user);

      return (success: true, user: user, message: null);
    }

    return (
      success: false,
      user: null,
      message: response.message ?? 'Erro ao fazer login',
    );
  }

  Future<({bool success, User? user, String? message})> register({
    required String nome,
    required String email,
    required String password,
    required String cargo,
    String setor = '',
  }) async {
    final response = await _api.post(
      ApiConfig.register,
      body: {
        'nome': nome,
        'email': email,
        'senha': password,
        'cargo': cargo,
        'setor': setor,
      },
    );

    if (response.success && response.data != null) {
      final token = response.data['token'] ?? '';
      final userData = response.data['usuario'] ?? response.data;
      final user = User.fromJson(userData);

      await _storage.saveToken(token);
      await _storage.saveUser(user);

      return (success: true, user: user, message: null);
    }

    return (
      success: false,
      user: null,
      message: response.message ?? 'Erro ao registrar',
    );
  }

  Future<User?> getMe() async {
    final response = await _api.get(ApiConfig.me);
    if (response.success && response.data != null) {
      final user = User.fromJson(response.data);
      await _storage.saveUser(user);
      return user;
    }
    return null;
  }

  Future<void> logout() async {
    await _storage.clearAll();
  }

  Future<bool> isAuthenticated() async {
    final token = await _storage.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<User?> getSavedUser() async {
    return await _storage.getUser();
  }
}
