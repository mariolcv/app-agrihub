import '../config/api_config.dart';
import '../models/recurso_model.dart';
import 'api_service.dart';

class RecursoService {
  final ApiService _apiService = ApiService();

  /// Obtiene lista de recursos filtrados por tipo de tarea
  Future<List<RecursoModel>> getRecursos({String? tipoTarea}) async {
    try {
      final queryParams = <String, String>{};
      if (tipoTarea != null && tipoTarea.isNotEmpty) {
        queryParams['tipo_tarea'] = tipoTarea;
      }

      final response = await _apiService.get(
        ApiConfig.recursosIndexEndpoint,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final List<dynamic> recursosJson = response['data'] ?? [];
      return recursosJson.map((json) => RecursoModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener recursos: $e');
    }
  }

  /// Obtiene todos los recursos (lista simplificada)
  Future<List<RecursoModel>> getAllRecursos() async {
    try {
      final response = await _apiService.get(
        ApiConfig.recursosAllEndpoint,
      );

      final List<dynamic> recursosJson = response['data'] ?? [];
      return recursosJson.map((json) => RecursoModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener todos los recursos: $e');
    }
  }

  /// Obtiene recursos completos agrupados por tipo de tarea
  Future<Map<String, List<RecursoModel>>> getRecursosComplete() async {
    try {
      final response = await _apiService.get(
        ApiConfig.recursosCompleteEndpoint,
      );

      final Map<String, dynamic> recursosData = response['data'] ?? {};
      final Map<String, List<RecursoModel>> result = {};
      
      recursosData.forEach((tipoTarea, recursos) {
        if (recursos is List) {
          result[tipoTarea] = recursos.map((json) => RecursoModel.fromJson(json)).toList();
        }
      });
      
      return result;
    } catch (e) {
      throw Exception('Error al obtener recursos completos: $e');
    }
  }

  /// Crea un nuevo recurso
  Future<RecursoModel> createRecurso({
    required String nombre,
    required String unidadConsumo,
    String? tipoTarea,
    required double precio,
    String? foto,
    double? kgMaPorUnidad,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.recursosNewEndpoint,
        body: {
          'nombre': nombre,
          'unidad_consumo': unidadConsumo,
          if (tipoTarea != null) 'tipo_tarea': tipoTarea,
          'precio': precio,
          if (foto != null) 'foto': foto,
          if (kgMaPorUnidad != null) 'kg_ma_por_unidad': kgMaPorUnidad,
        },
      );

      final recursoData = response['data'] ?? response;
      return RecursoModel.fromJson(recursoData);
    } catch (e) {
      throw Exception('Error al crear recurso: $e');
    }
  }

  /// Crea un nuevo precio para un recurso
  Future<void> createPrecioRecurso({
    required int idRecurso,
    required double precioUnitario,
    required String fecha,
  }) async {
    try {
      await _apiService.post(
        ApiConfig.recursosPrecioEndpoint,
        body: {
          'id_recurso': idRecurso,
          'precio_unitario': precioUnitario,
          'fecha': fecha,
        },
      );
    } catch (e) {
      throw Exception('Error al crear precio de recurso: $e');
    }
  }
}
