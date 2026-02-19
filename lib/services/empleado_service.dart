import '../config/api_config.dart';
import '../models/empleado_model.dart';
import '../models/nomina_model.dart';
import 'api_service.dart';

class EmpleadoService {
  final ApiService _apiService = ApiService();

  // Obtener empleados visibles con filtro opcional por cargo
  Future<List<EmpleadoModel>> getEmpleados({String? cargo}) async {
    try {
      final queryParams = <String, String>{};
      if (cargo != null && cargo.isNotEmpty) {
        queryParams['cargo'] = cargo;
      }

      final response = await _apiService.get(
        ApiConfig.empleadosIndexEndpoint,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final List<dynamic> empleadosJson = response['data'] ?? response['empleados'] ?? [];
      return empleadosJson.map((json) => EmpleadoModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener empleados: $e');
    }
  }

  // Obtener todos los empleados (incluidos los no visibles)
  Future<List<EmpleadoModel>> getAllEmpleados() async {
    try {
      final response = await _apiService.get(
        ApiConfig.empleadosAllEndpoint,
      );

      final List<dynamic> empleadosJson = response['data'] ?? response['empleados'] ?? [];
      return empleadosJson.map((json) => EmpleadoModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener todos los empleados: $e');
    }
  }

  // Obtener empleado por ID
  Future<EmpleadoModel> getEmpleadoById(int id) async {
    try {
      final response = await _apiService.get(
        ApiConfig.empleadoByIdEndpoint(id),
      );

      return EmpleadoModel.fromJson(response['empleado'] ?? response);
    } catch (e) {
      throw Exception('Error al obtener empleado: $e');
    }
  }

  // Crear nuevo empleado
  Future<EmpleadoModel> createEmpleado({
    required String nombre,
    String? cargo,
    String? cargo2,
    String? foto,
    String? nuevoCargo,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.empleadosNewEndpoint,
        body: {
          'nombre': nombre,
          if (cargo != null) 'cargo': cargo,
          if (cargo2 != null) 'cargo2': cargo2,
          if (foto != null) 'foto': foto,
          if (nuevoCargo != null) 'nuevoCargo': nuevoCargo,
        },
      );

      return EmpleadoModel.fromJson(response['empleado'] ?? response);
    } catch (e) {
      throw Exception('Error al crear empleado: $e');
    }
  }

  // Dar de baja empleado
  Future<void> deleteEmpleado(int id) async {
    try {
      await _apiService.delete(
        ApiConfig.empleadosDeleteEndpoint(id),
      );
    } catch (e) {
      throw Exception('Error al dar de baja empleado: $e');
    }
  }

  // Reactivar empleado
  Future<void> reactivarEmpleado(int id) async {
    try {
      await _apiService.post(
        ApiConfig.empleadosReactivarEndpoint(id),
      );
    } catch (e) {
      throw Exception('Error al reactivar empleado: $e');
    }
  }

  // Obtener cargos de empleados
  Future<List<CargoEmpleado>> getCargos() async {
    try {
      final response = await _apiService.get(
        ApiConfig.cargosEmpleadosEndpoint,
      );

      final List<dynamic> cargosJson = response['data'] ?? response['cargos'] ?? [];
      return cargosJson.map((json) => CargoEmpleado.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener cargos: $e');
    }
  }

  // Crear nómina
  Future<NominaModel> createNomina({
    required int idEmpleado,
    required int anio,
    required int mes,
    required double salarioBruto,
    required double horasTrabajadas,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.nominaCreateEndpoint,
        body: {
          'id_empleado': idEmpleado,
          'anio': anio,
          'mes': mes,
          'salario_bruto': salarioBruto,
          'horas_trabajadas': horasTrabajadas,
        },
      );

      return NominaModel.fromJson(response['nomina'] ?? response);
    } catch (e) {
      throw Exception('Error al crear nómina: $e');
    }
  }

  // Obtener nóminas de un empleado
  Future<List<NominaModel>> getNominasByEmpleado(int empleadoId) async {
    try {
      final response = await _apiService.get(
        ApiConfig.nominasByEmpleadoEndpoint(empleadoId),
      );

      final List<dynamic> nominasJson = response['data'] ?? response['nominas'] ?? [];
      return nominasJson.map((json) => NominaModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener nóminas: $e');
    }
  }

  // Actualizar nómina
  Future<NominaModel> updateNomina({
    required int id,
    required double salarioBruto,
    required double horasTrabajadas,
  }) async {
    try {
      final response = await _apiService.put(
        ApiConfig.nominaUpdateEndpoint(id),
        body: {
          'salario_bruto': salarioBruto,
          'horas_trabajadas': horasTrabajadas,
        },
      );

      return NominaModel.fromJson(response['nomina'] ?? response);
    } catch (e) {
      throw Exception('Error al actualizar nómina: $e');
    }
  }

  // Eliminar nómina
  Future<void> deleteNomina(int id) async {
    try {
      await _apiService.delete(
        ApiConfig.nominaDeleteEndpoint(id),
      );
    } catch (e) {
      throw Exception('Error al eliminar nómina: $e');
    }
  }
}
