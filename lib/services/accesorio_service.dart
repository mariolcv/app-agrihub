import '../config/api_config.dart';
import '../models/accesorio_model.dart';
import 'api_service.dart';

class AccesorioService {
  final ApiService _apiService = ApiService();

  /// Obtiene lista de accesorios filtrados por tipo de tarea
  Future<List<AccesorioModel>> getAccesorios({String? tipoTarea}) async {
    try {
      final queryParams = <String, String>{};
      if (tipoTarea != null && tipoTarea.isNotEmpty) {
        queryParams['tipo_tarea'] = tipoTarea;
      }

      final response = await _apiService.get(
        ApiConfig.accesoriosIndexEndpoint,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final List<dynamic> accesoriosJson = response['data'] ?? [];
      return accesoriosJson.map((json) => AccesorioModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener accesorios: $e');
    }
  }

  /// Obtiene todos los accesorios con sus tarifas
  Future<List<AccesorioModel>> getAllAccesorios() async {
    try {
      final response = await _apiService.get(
        ApiConfig.accesoriosAllEndpoint,
      );

      final List<dynamic> accesoriosJson = response['data'] ?? [];
      return accesoriosJson.map((json) => AccesorioModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener todos los accesorios: $e');
    }
  }

  /// Crea un nuevo accesorio
  Future<AccesorioModel> createAccesorio({
    required String nombre,
    String? tipo,
    required double factorConsumo,
    double? costeHora,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.accesoriosNewEndpoint,
        body: {
          'nombre': nombre,
          if (tipo != null) 'tipo': tipo,
          'factor_consumo': factorConsumo,
          if (costeHora != null) 'coste_hora': costeHora,
        },
      );

      final accesorioData = response['data']?['accesorio'] ?? response['accesorio'] ?? response;
      return AccesorioModel.fromJson(accesorioData);
    } catch (e) {
      throw Exception('Error al crear accesorio: $e');
    }
  }

  /// Elimina un accesorio
  Future<void> deleteAccesorio(int id) async {
    try {
      await _apiService.delete(
        ApiConfig.accesoriosDeleteEndpoint(id),
      );
    } catch (e) {
      throw Exception('Error al eliminar accesorio: $e');
    }
  }
}
