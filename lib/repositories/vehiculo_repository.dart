import '../models/vehiculo_model.dart';
import '../services/vehiculo_service.dart';

/// Repository para gestión de vehículos
/// Implementa el patrón Repository y Singleton para centralizar el acceso a datos
/// Proporciona cache en memoria para optimizar las llamadas al API
class VehiculoRepository {
  // Patrón Singleton
  static final VehiculoRepository _instance = VehiculoRepository._internal();
  factory VehiculoRepository() => _instance;
  VehiculoRepository._internal();

  final VehiculoService _vehiculoService = VehiculoService();
  
  // Cache de vehículos
  List<VehiculoModel>? _vehiculosCache;
  DateTime? _lastCacheUpdate;
  
  // Duración del cache (5 minutos)
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Obtiene todos los vehículos con sus tarifas
  /// Utiliza cache para optimizar llamadas repetidas
  Future<List<VehiculoModel>> getVehiculos({bool forceRefresh = false}) async {
    // Verificar si el cache es válido
    if (!forceRefresh && 
        _vehiculosCache != null && 
        _lastCacheUpdate != null &&
        DateTime.now().difference(_lastCacheUpdate!) < _cacheDuration) {
      return _vehiculosCache!;
    }

    try {
      // NOTA: Usar endpoint básico en lugar de 'all' porque 'all' no devuelve el campo 'id'
      // TODO: Actualizar el backend para que /vehiculos/all incluya el campo 'id'
      final vehiculos = await _vehiculoService.getVehiculos();
      _vehiculosCache = vehiculos;
      _lastCacheUpdate = DateTime.now();
      return vehiculos;
    } catch (e) {
      // Si falla y hay cache, devolver cache aunque esté expirado
      if (_vehiculosCache != null) {
        return _vehiculosCache!;
      }
      throw Exception('Error al obtener vehículos: $e');
    }
  }

  /// Obtiene solo las matrículas de los vehículos
  Future<List<String>> getMatriculas({bool forceRefresh = false}) async {
    final vehiculos = await getVehiculos(forceRefresh: forceRefresh);
    return vehiculos.map((v) => v.matricula).toList();
  }

  /// Obtiene solo los nombres de los vehículos
  Future<List<String>> getNombresVehiculos({bool forceRefresh = false}) async {
    final vehiculos = await getVehiculos(forceRefresh: forceRefresh);
    return vehiculos.map((v) => v.nombre).toList();
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
      final vehiculo = await _vehiculoService.createVehiculo(
        matricula: matricula,
        nombre: nombre,
        tipo: tipo,
        marca: marca,
        modelo: modelo,
        combustible: combustible,
        consumo: consumo,
        foto: foto,
      );
      
      // Invalidar cache
      clearCache();
      
      return vehiculo;
    } catch (e) {
      throw Exception('Error al crear vehículo: $e');
    }
  }

  /// Elimina un vehículo
  Future<void> deleteVehiculo(String matricula) async {
    try {
      await _vehiculoService.deleteVehiculo(matricula);
      
      // Invalidar cache
      clearCache();
    } catch (e) {
      throw Exception('Error al eliminar vehículo: $e');
    }
  }

  /// Limpia el cache
  void clearCache() {
    _vehiculosCache = null;
    _lastCacheUpdate = null;
  }
}
