import '../models/recurso_model.dart';
import '../services/recurso_service.dart';

/// Repository para gestión de recursos
/// Implementa el patrón Repository y Singleton para centralizar el acceso a datos
/// Proporciona cache en memoria para optimizar las llamadas al API
class RecursoRepository {
  // Patrón Singleton
  static final RecursoRepository _instance = RecursoRepository._internal();
  factory RecursoRepository() => _instance;
  RecursoRepository._internal();

  final RecursoService _recursoService = RecursoService();
  
  // Cache de recursos
  List<RecursoModel>? _recursosCache;
  DateTime? _lastCacheUpdate;
  
  // Duración del cache (5 minutos)
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Obtiene todos los recursos
  /// Utiliza cache para optimizar llamadas repetidas
  Future<List<RecursoModel>> getRecursos({bool forceRefresh = false}) async {
    // Verificar si el cache es válido
    if (!forceRefresh && 
        _recursosCache != null && 
        _lastCacheUpdate != null &&
        DateTime.now().difference(_lastCacheUpdate!) < _cacheDuration) {
      return _recursosCache!;
    }

    try {
      final recursos = await _recursoService.getAllRecursos();
      _recursosCache = recursos;
      _lastCacheUpdate = DateTime.now();
      return recursos;
    } catch (e) {
      // Si falla y hay cache, devolver cache aunque esté expirado
      if (_recursosCache != null) {
        return _recursosCache!;
      }
      throw Exception('Error al obtener recursos: $e');
    }
  }

  /// Obtiene solo los nombres de los recursos
  Future<List<String>> getNombresRecursos({bool forceRefresh = false}) async {
    final recursos = await getRecursos(forceRefresh: forceRefresh);
    return recursos.map((r) => r.nombre).toList();
  }

  /// Obtiene solo los nombres de los recursos filtrados por tipo de tarea
  Future<List<String>> getNombresRecursosByTipo(String tipoTarea) async {
    final recursos = await getRecursosByTipo(tipoTarea);
    return recursos.map((r) => r.nombre).toList();
  }

  /// Obtiene recursos filtrados por tipo de tarea
  Future<List<RecursoModel>> getRecursosByTipo(String tipoTarea) async {
    try {
      return await _recursoService.getRecursos(tipoTarea: tipoTarea);
    } catch (e) {
      throw Exception('Error al obtener recursos por tipo: $e');
    }
  }

  /// Obtiene recursos completos agrupados por tipo de tarea
  Future<Map<String, List<RecursoModel>>> getRecursosComplete() async {
    try {
      return await _recursoService.getRecursosComplete();
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
      final recurso = await _recursoService.createRecurso(
        nombre: nombre,
        unidadConsumo: unidadConsumo,
        tipoTarea: tipoTarea,
        precio: precio,
        foto: foto,
        kgMaPorUnidad: kgMaPorUnidad,
      );
      
      // Invalidar cache
      clearCache();
      
      return recurso;
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
      await _recursoService.createPrecioRecurso(
        idRecurso: idRecurso,
        precioUnitario: precioUnitario,
        fecha: fecha,
      );
      
      // Invalidar cache para refrescar precios
      clearCache();
    } catch (e) {
      throw Exception('Error al crear precio de recurso: $e');
    }
  }

  /// Limpia el cache
  void clearCache() {
    _recursosCache = null;
    _lastCacheUpdate = null;
  }
}
