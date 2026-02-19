import '../models/accesorio_model.dart';
import '../services/accesorio_service.dart';

/// Repository para gestión de accesorios/aperos
/// Implementa el patrón Repository y Singleton para centralizar el acceso a datos
/// Proporciona cache en memoria para optimizar las llamadas al API
class AccesorioRepository {
  // Patrón Singleton
  static final AccesorioRepository _instance = AccesorioRepository._internal();
  factory AccesorioRepository() => _instance;
  AccesorioRepository._internal();

  final AccesorioService _accesorioService = AccesorioService();
  
  // Cache de accesorios
  List<AccesorioModel>? _accesoriosCache;
  DateTime? _lastCacheUpdate;
  
  // Duración del cache (5 minutos)
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Obtiene todos los accesorios
  /// Utiliza cache para optimizar llamadas repetidas
  Future<List<AccesorioModel>> getAccesorios({bool forceRefresh = false}) async {
    // Verificar si el cache es válido
    if (!forceRefresh && 
        _accesoriosCache != null && 
        _lastCacheUpdate != null &&
        DateTime.now().difference(_lastCacheUpdate!) < _cacheDuration) {
      return _accesoriosCache!;
    }

    try {
      final accesorios = await _accesorioService.getAllAccesorios();
      _accesoriosCache = accesorios;
      _lastCacheUpdate = DateTime.now();
      return accesorios;
    } catch (e) {
      // Si falla y hay cache, devolver cache aunque esté expirado
      if (_accesoriosCache != null) {
        return _accesoriosCache!;
      }
      throw Exception('Error al obtener accesorios: $e');
    }
  }

  /// Obtiene solo los nombres de los accesorios
  Future<List<String>> getNombresAccesorios({bool forceRefresh = false}) async {
    final accesorios = await getAccesorios(forceRefresh: forceRefresh);
    return accesorios.map((a) => a.nombre).toList();
  }

  /// Obtiene accesorios filtrados por tipo de tarea
  Future<List<AccesorioModel>> getAccesoriosByTipo(String tipoTarea) async {
    try {
      return await _accesorioService.getAccesorios(tipoTarea: tipoTarea);
    } catch (e) {
      throw Exception('Error al obtener accesorios por tipo: $e');
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
      final accesorio = await _accesorioService.createAccesorio(
        nombre: nombre,
        tipo: tipo,
        factorConsumo: factorConsumo,
        costeHora: costeHora,
      );
      
      // Invalidar cache
      clearCache();
      
      return accesorio;
    } catch (e) {
      throw Exception('Error al crear accesorio: $e');
    }
  }

  /// Elimina un accesorio
  Future<void> deleteAccesorio(int id) async {
    try {
      await _accesorioService.deleteAccesorio(id);
      
      // Invalidar cache
      clearCache();
    } catch (e) {
      throw Exception('Error al eliminar accesorio: $e');
    }
  }

  /// Limpia el cache
  void clearCache() {
    _accesoriosCache = null;
    _lastCacheUpdate = null;
  }
}
