import '../services/empleado_service.dart';
import '../models/empleado_model.dart';

/// Repository para gestión de empleados
/// Implementa el patrón Repository y Singleton para centralizar el acceso a datos
/// Proporciona cache en memoria para optimizar las llamadas al API
class EmpleadoRepository {
  // Patrón Singleton
  static final EmpleadoRepository _instance = EmpleadoRepository._internal();
  factory EmpleadoRepository() => _instance;
  EmpleadoRepository._internal();

  final EmpleadoService _empleadoService = EmpleadoService();
  
  // Cache de empleados
  List<EmpleadoModel>? _empleadosCache;
  DateTime? _lastCacheUpdate;
  
  // Duración del cache (5 minutos)
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Obtiene todos los empleados visibles
  /// Utiliza cache para optimizar llamadas repetidas
  Future<List<EmpleadoModel>> getEmpleados({bool forceRefresh = false}) async {
    // Verificar si el cache es válido
    if (!forceRefresh && 
        _empleadosCache != null && 
        _lastCacheUpdate != null &&
        DateTime.now().difference(_lastCacheUpdate!) < _cacheDuration) {
      return _empleadosCache!;
    }

    try {
      final empleados = await _empleadoService.getEmpleados();
      _empleadosCache = empleados;
      _lastCacheUpdate = DateTime.now();
      return empleados;
    } catch (e) {
      // Si falla y hay cache, devolver cache aunque esté expirado
      if (_empleadosCache != null) {
        return _empleadosCache!;
      }
      throw Exception('Error al obtener empleados: $e');
    }
  }

  /// Obtiene solo los nombres de los empleados
  Future<List<String>> getNombresEmpleados({bool forceRefresh = false}) async {
    final empleados = await getEmpleados(forceRefresh: forceRefresh);
    return empleados.map((e) => e.nombre).toList();
  }

  /// Obtiene solo los nombres de los empleados que son agricultores
  Future<List<String>> getNombresAgricultores({bool forceRefresh = false}) async {
    final empleados = await getEmpleados(forceRefresh: forceRefresh);
    final agricultores = empleados.where((e) => 
      e.cargo?.toLowerCase() == 'agricultor' || 
      e.cargo2?.toLowerCase() == 'agricultor'
    );
    return agricultores.map((e) => e.nombre).toList();
  }

  /// Obtiene todos los empleados (incluidos no visibles)
  Future<List<EmpleadoModel>> getAllEmpleados() async {
    try {
      return await _empleadoService.getAllEmpleados();
    } catch (e) {
      throw Exception('Error al obtener todos los empleados: $e');
    }
  }

  /// Obtiene empleado por ID
  Future<EmpleadoModel> getEmpleadoById(int id) async {
    try {
      return await _empleadoService.getEmpleadoById(id);
    } catch (e) {
      throw Exception('Error al obtener empleado: $e');
    }
  }

  /// Crea un nuevo empleado
  Future<EmpleadoModel> createEmpleado({
    required String nombre,
    String? cargo,
    String? cargo2,
    String? foto,
    String? nuevoCargo,
  }) async {
    try {
      final empleado = await _empleadoService.createEmpleado(
        nombre: nombre,
        cargo: cargo,
        cargo2: cargo2,
        foto: foto,
        nuevoCargo: nuevoCargo,
      );
      
      // Invalidar cache
      clearCache();
      
      return empleado;
    } catch (e) {
      throw Exception('Error al crear empleado: $e');
    }
  }

  /// Dar de baja empleado
  Future<void> deleteEmpleado(int id) async {
    try {
      await _empleadoService.deleteEmpleado(id);
      
      // Invalidar cache
      clearCache();
    } catch (e) {
      throw Exception('Error al dar de baja empleado: $e');
    }
  }

  /// Reactivar empleado
  Future<void> reactivarEmpleado(int id) async {
    try {
      await _empleadoService.reactivarEmpleado(id);
      
      // Invalidar cache
      clearCache();
    } catch (e) {
      throw Exception('Error al reactivar empleado: $e');
    }
  }

  /// Limpia el cache
  void clearCache() {
    _empleadosCache = null;
    _lastCacheUpdate = null;
  }
}
