import '../config/api_config.dart';
import '../models/parcela_model.dart';
import 'api_service.dart';

class ParcelaService {
  final ApiService _apiService = ApiService();

  // Obtener parcelas agrupadas
  Future<List<ParcelaGrouped>> getParcelasGrouped() async {
    try {
      final response = await _apiService.get(
        ApiConfig.parcelasIndexEndpoint,
      );

      final List<dynamic> parcelasJson = response['data'] ?? response['parcelas'] ?? [];
      return parcelasJson.map((json) => ParcelaGrouped.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener parcelas: $e');
    }
  }

  // Obtener todas las parcelas en formato raw (sin agrupación)
  Future<List<ParcelaModel>> getAllParcelasRaw() async {
    try {
      final response = await _apiService.get(
        ApiConfig.parcelasAllRawEndpoint,
      );

      final List<dynamic> parcelasJson = response['data'] ?? [];
      return parcelasJson.map((json) => ParcelaModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener parcelas raw: $e');
    }
  }

  // Obtener opciones únicas (fincas o variedades)
  Future<List<String>> getParcelaOptions(String field) async {
    try {
      final response = await _apiService.get(
        ApiConfig.parcelasOptionsEndpoint,
        queryParameters: {'field': field},
      );

      final List<dynamic> optionsJson = response['data'] ?? response['options'] ?? [];
      return optionsJson.map((e) => e.toString()).toList();
    } catch (e) {
      throw Exception('Error al obtener opciones de parcelas: $e');
    }
  }

  // Obtener parcela por ID
  Future<ParcelaModel> getParcelaById(int id) async {
    try {
      final response = await _apiService.get(
        ApiConfig.parcelaByIdEndpoint(id),
      );

      return ParcelaModel.fromJson(response['parcela'] ?? response);
    } catch (e) {
      throw Exception('Error al obtener parcela: $e');
    }
  }

  // Crear parcela
  Future<ParcelaModel> createParcela({
    required String finca,
    String? propietario,
    String? paraje,
    int? poligono,
    String? numParcela,
    double? superficie,
    int? numArboles,
    String? variedad,
    String? anoPlantacion,
    String? situacionEspecial,
    String? fruto,
    double? distanciaAlmacenKm,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.parcelasNewEndpoint,
        body: {
          'finca': finca,
          if (propietario != null) 'propietario': propietario,
          if (paraje != null) 'paraje': paraje,
          if (poligono != null) 'poligono': poligono,
          if (numParcela != null) 'num_parcela': numParcela,
          if (superficie != null) 'superficie': superficie,
          if (numArboles != null) 'num_arboles': numArboles,
          if (variedad != null) 'variedad': variedad,
          if (anoPlantacion != null) 'ano_plantacion': anoPlantacion,
          if (situacionEspecial != null) 'situacion_especial': situacionEspecial,
          if (fruto != null) 'fruto': fruto,
          if (distanciaAlmacenKm != null) 'distancia_almacen_km': distanciaAlmacenKm,
        },
      );

      return ParcelaModel.fromJson(response['parcela'] ?? response);
    } catch (e) {
      throw Exception('Error al crear parcela: $e');
    }
  }

  // Actualizar parcela
  Future<ParcelaModel> updateParcela(int id, Map<String, dynamic> updates) async {
    try {
      final response = await _apiService.put(
        ApiConfig.parcelasUpdateEndpoint(id),
        body: updates,
      );

      return ParcelaModel.fromJson(response['parcela'] ?? response);
    } catch (e) {
      throw Exception('Error al actualizar parcela: $e');
    }
  }

  // Eliminar parcela
  Future<void> deleteParcela(int id) async {
    try {
      await _apiService.delete(
        ApiConfig.parcelasDeleteEndpoint(id),
      );
    } catch (e) {
      throw Exception('Error al eliminar parcela: $e');
    }
  }
}
