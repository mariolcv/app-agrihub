import '../config/api_config.dart';
import '../models/vehiculo_model.dart';
import 'api_service.dart';

class VehiculoService {
  final ApiService _apiService = ApiService();

  /// Obtiene lista básica de vehículos
  Future<List<VehiculoModel>> getVehiculos() async {
    try {
      final response = await _apiService.get(
        ApiConfig.vehiculosIndexEndpoint,
      );

      final List<dynamic> vehiculosJson = response['data'] ?? [];
      return vehiculosJson.map((json) => VehiculoModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener vehículos: $e');
    }
  }

  /// Obtiene todos los vehículos con tarifas de consumo
  Future<List<VehiculoModel>> getAllVehiculos() async {
    try {
      final response = await _apiService.get(
        ApiConfig.vehiculosAllEndpoint,
      );

      final List<dynamic> vehiculosJson = response['data'] ?? [];
      return vehiculosJson.map((json) => VehiculoModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener todos los vehículos: $e');
    }
  }

  /// Crea un nuevo vehículo
  Future<VehiculoModel> createVehiculo({
    required String matricula,
    required String nombre,
    required String tipo,
    required String marca,
    String? modelo,
    required String combustible,
    required double consumo,
    String? foto,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.vehiculosNewEndpoint,
        body: {
          'matricula': matricula,
          'nombre': nombre,
          'tipo': tipo,
          'marca': marca,
          if (modelo != null) 'modelo': modelo,
          'combustible': combustible,
          'consumo': consumo,
          if (foto != null) 'foto': foto,
        },
      );

      return VehiculoModel.fromJson(response['vehiculo'] ?? response);
    } catch (e) {
      throw Exception('Error al crear vehículo: $e');
    }
  }

  /// Elimina un vehículo
  Future<void> deleteVehiculo(String matricula) async {
    try {
      await _apiService.delete(
        ApiConfig.vehiculosDeleteEndpoint(matricula),
      );
    } catch (e) {
      throw Exception('Error al eliminar vehículo: $e');
    }
  }
}
