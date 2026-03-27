import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../config/api_config.dart';
import 'app_logger.dart';

void print(Object? message) => AppLogger.i(message);

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static final _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: false,
    ),
  );

  String? _accessToken;
  String? _refreshToken;

  // Obtener los tokens guardados
  Future<void> loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
  }

  // Guardar tokens
  Future<void> saveTokens(String? accessToken, String? refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    
    if (accessToken != null) {
      await prefs.setString('access_token', accessToken);
    } else {
      await prefs.remove('access_token');
    }
    
    if (refreshToken != null) {
      await prefs.setString('refresh_token', refreshToken);
    } else {
      await prefs.remove('refresh_token');
    }
  }

  // Limpiar tokens
  Future<void> clearTokens() async {
    await saveTokens(null, null);
  }

  // Obtener headers con autenticación
  Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
    };
    
    if (includeAuth && _accessToken != null) {
      headers['Cookie'] = 'access_token=$_accessToken';
      if (_refreshToken != null) {
        headers['Cookie'] = '${headers['Cookie']}; refresh_token=$_refreshToken';
      }
    }
    
    return headers;
  }

  // Extraer cookies de la respuesta
  void _extractTokensFromResponse(http.Response response) {
    final setCookieHeader = response.headers['set-cookie'];
    if (setCookieHeader != null) {
      final cookies = setCookieHeader.split(',');
      for (var cookie in cookies) {
        if (cookie.contains('access_token=')) {
          final token = cookie.split('access_token=')[1].split(';')[0];
          _accessToken = token;
        }
        if (cookie.contains('refresh_token=')) {
          final token = cookie.split('refresh_token=')[1].split(';')[0];
          _refreshToken = token;
        }
      }
      saveTokens(_accessToken, _refreshToken);
    }
  }

  // Método GET
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParameters,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint')
          .replace(queryParameters: queryParameters);
      
      final response = await http.get(
        uri,
        headers: _getHeaders(includeAuth: requiresAuth),
      ).timeout(ApiConfig.connectionTimeout);

      return _handleResponse(response);
    } on http.ClientException catch (e) {
      throw Exception('Error de conexión: ${e.message}.\nVerifica que el servidor esté corriendo en ${ApiConfig.baseUrl}');
    } on SocketException {
      throw Exception('No hay conexión a Internet');
    } on HttpException {
      throw Exception('No se pudo encontrar el servidor');
    } on FormatException {
      throw Exception('Respuesta en formato incorrecto');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  // Método POST
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      
      print('🌐 [ApiService] POST Request:');
      print('   URI: $uri');
      print('   Body keys: ${body?.keys.toList() ?? "null"}');
      
      final response = await http.post(
        uri,
        headers: _getHeaders(includeAuth: requiresAuth),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(ApiConfig.connectionTimeout);

      print('🌐 [ApiService] POST Response:');
      print('   Status: ${response.statusCode}');
      print('   Body length: ${response.body.length} chars');
      print('   Body preview (first 500 chars): ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');

      _extractTokensFromResponse(response);
      
      final handledResponse = _handleResponse(response);
      print('🌐 [ApiService] Response after _handleResponse:');
      print('   Type: ${handledResponse.runtimeType}');
      print('   Keys: ${handledResponse.keys.toList()}');
      
      return handledResponse;
    } on SocketException {
      throw Exception('No hay conexión a Internet. Verifica tu conexión.');
    } on HttpException {
      throw Exception('No se pudo encontrar el servidor en ${ApiConfig.baseUrl}');
    } on FormatException {
      throw Exception('Respuesta en formato incorrecto del servidor');
    } on http.ClientException catch (e) {
      throw Exception('Error de conexión: ${e.message}.\nVerifica que el servidor esté corriendo en ${ApiConfig.baseUrl}');
    } catch (e, stackTrace) {
      if (e is Exception) {
        rethrow;
      }
      print('❌ [ApiService] POST Error:');
      print('   Error: $e');
      print('   Type: ${e.runtimeType}');
      print('   Stack (first 10 lines):');
      print(stackTrace.toString().split('\n').take(10).join('\n'));
      throw Exception('Error inesperado: $e');
    }
  }

  // Método PUT
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      
      final response = await http.put(
        uri,
        headers: _getHeaders(includeAuth: requiresAuth),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(ApiConfig.connectionTimeout);

      return _handleResponse(response);
    } on http.ClientException catch (e) {
      throw Exception('Error de conexión (PUT ${ApiConfig.baseUrl}$endpoint): ${e.message}');
    } on SocketException {
      throw Exception('No hay conexión a Internet');
    } on HttpException {
      throw Exception('No se pudo encontrar el servidor');
    } on FormatException {
      throw Exception('Respuesta en formato incorrecto');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  // Método PATCH
  Future<Map<String, dynamic>> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      print('🔧 [ApiService.patch] Iniciando PATCH request:');
      print('   URL: ${ApiConfig.baseUrl}$endpoint');
      print('   Body: $body');
      
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      
      final response = await http.patch(
        uri,
        headers: _getHeaders(includeAuth: requiresAuth),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(ApiConfig.connectionTimeout);

      print('🔧 [ApiService.patch] Respuesta recibida:');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      return _handleResponse(response);
    } on http.ClientException catch (e) {
      print('❌ [ApiService.patch] ClientException: ${e.message}');
      throw Exception('Error de conexión (PATCH ${ApiConfig.baseUrl}$endpoint): ${e.message}');
    } on SocketException {
      print('❌ [ApiService.patch] SocketException');
      throw Exception('No hay conexión a Internet');
    } on HttpException {
      print('❌ [ApiService.patch] HttpException');
      throw Exception('No se pudo encontrar el servidor');
    } on FormatException {
      print('❌ [ApiService.patch] FormatException');
      throw Exception('Respuesta en formato incorrecto');
    } catch (e) {
      print('❌ [ApiService.patch] Error inesperado: $e');
      throw Exception('Error inesperado: $e');
    }
  }

  // Método DELETE
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      
      final response = await http.delete(
        uri,
        headers: _getHeaders(includeAuth: requiresAuth),
      ).timeout(ApiConfig.connectionTimeout);

      return _handleResponse(response);
    } on http.ClientException catch (e) {
      throw Exception('Error de conexión (DELETE ${ApiConfig.baseUrl}$endpoint): ${e.message}');
    } on SocketException {
      throw Exception('No hay conexión a Internet');
    } on HttpException {
      throw Exception('No se pudo encontrar el servidor');
    } on FormatException {
      throw Exception('Respuesta en formato incorrecto');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  // Manejar la respuesta
  Map<String, dynamic> _handleResponse(http.Response response) {
    print('🔍 [ApiService._handleResponse] Procesando respuesta:');
    print('   Status code: ${response.statusCode}');
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        print('   ⚠️ Body vacío, devolviendo success genérico');
        return {'success': true};
      }
      try {
        print('   📦 Decodificando JSON...');
        final decoded = jsonDecode(response.body);
        print('   ✅ JSON decodificado correctamente');
        print('   Tipo: ${decoded.runtimeType}');
        
        if (decoded is Map<String, dynamic>) {
          print('   📋 Es Map<String, dynamic> - devolviendo directamente');
          return decoded;
        } else if (decoded is List) {
          print('   📋 Es List - envolviendo en data');
          return {'data': decoded};
        } else {
          print('   📋 Es otro tipo - envolviendo en data');
          return {'data': decoded};
        }
      } catch (e) {
        print('   ❌ Error decodificando JSON: $e');
        _logger.e('Error decoding JSON', error: e);
        return {'success': true, 'raw': response.body};
      }
    } else if (response.statusCode == 401) {
      throw Exception('No autorizado. Por favor, inicia sesión nuevamente.');
    } else if (response.statusCode == 404) {
      throw Exception('Recurso no encontrado');
    } else if (response.statusCode == 409) {
      throw Exception('Conflicto: el recurso ya existe');
    } else if (response.statusCode >= 500) {
      throw Exception('Error del servidor');
    } else {
      try {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? error['message'] ?? 'Error desconocido');
      } catch (e) {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    }
  }

  // Verificar si hay sesión activa
  bool get isAuthenticated => _accessToken != null;
}
