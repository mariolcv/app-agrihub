import 'package:logger/logger.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  static final _logger = Logger();

  // Login
  Future<UserModel> login(String email, String password) async {
    try {
      _logger.i('Intentando login para: $email');
      _logger.d('Endpoint: ${ApiConfig.baseUrl}${ApiConfig.loginEndpoint}');
      
      final response = await _apiService.post(
        ApiConfig.loginEndpoint,
        body: {
          'email': email,
          'password': password,
        },
        requiresAuth: false,
      );

      _logger.i('Login response recibida');
      _logger.d('Response keys: ${response.keys.join(", ")}');

      // Intentar con formato {user: {...}} o directo {...}
      if (response['user'] != null) {
        _logger.d('Formato detectado: anidado en user');
        return UserModel.fromJson(response['user']);
      } else if (response['email'] != null || response['username'] != null || response['name'] != null) {
        _logger.d('Formato detectado: respuesta directa');
        // Respuesta directa sin anidación
        return UserModel.fromJson(response);
      } else {
        _logger.e('Formato de respuesta no reconocido');
        throw Exception('Respuesta inválida del servidor. Datos recibidos: ${response.keys.join(", ")}');
      }
    } catch (e) {
      _logger.e('Error en login', error: e);
      throw Exception('Error al iniciar sesión: $e');
    }
  }

  // Register
  Future<UserModel> register({
    required String username,
    required String email,
    required String password,
    String? confirmPassword,
    int? empleadoId,
    String? oneTimePassword,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.registerEndpoint,
        body: {
          'username': username,
          'email': email,
          'password': password,
          if (confirmPassword != null) 'confirmPassword': confirmPassword,
          if (empleadoId != null) 'empleadoId': empleadoId,
          if (oneTimePassword != null) 'one_time_pswd': oneTimePassword,
        },
        requiresAuth: false,
      );

      // El endpoint devuelve directamente los campos, no anidados en 'user'
      return UserModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al registrar usuario: $e');
    }
  }

  // Get current user
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _apiService.get(
        ApiConfig.meEndpoint,
        requiresAuth: true,
      );

      if (response['user'] != null) {
        return UserModel.fromJson(response['user']);
      }

      if (response['data'] != null && response['data'] is Map<String, dynamic>) {
        return UserModel.fromJson(response['data']);
      }

      if (response['email'] != null ||
          response['username'] != null ||
          response['name'] != null) {
        return UserModel.fromJson(response);
      }

      throw Exception('Respuesta inválida del servidor');
    } catch (e) {
      throw Exception('Error al obtener usuario actual: $e');
    }
  }

  // Refresh token
  Future<void> refreshToken() async {
    try {
      await _apiService.post(
        ApiConfig.refreshEndpoint,
        requiresAuth: true,
      );
    } catch (e) {
      throw Exception('Error al refrescar token: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _apiService.post(
        ApiConfig.logoutEndpoint,
        requiresAuth: true,
      );
      await _apiService.clearTokens();
    } catch (e) {
      // Limpiar tokens incluso si falla la petición
      await _apiService.clearTokens();
      throw Exception('Error al cerrar sesión: $e');
    }
  }

  // Check if authenticated
  Future<bool> isAuthenticated() async {
    await _apiService.loadTokens();
    return _apiService.isAuthenticated;
  }
}
