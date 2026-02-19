import '../services/parcela_service.dart';
import '../models/parcela_model.dart';

/// Repository para gestión de parcelas
/// Implementa el patrón Repository y Singleton para centralizar el acceso a datos
/// Proporciona cache en memoria para optimizar las llamadas al API
class ParcelaRepository {
  // Patrón Singleton
  static final ParcelaRepository _instance = ParcelaRepository._internal();
  factory ParcelaRepository() => _instance;
  ParcelaRepository._internal();

  final ParcelaService _parcelaService = ParcelaService();
  
  // Cache
  List<ParcelaGrouped>? _parcelasGroupedCache;
  List<ParcelaModel>? _parcelasCache;
  List<String>? _fincasCache;
  List<String>? _variedadesCache;
  DateTime? _lastCacheUpdate;
  DateTime? _parcelasCacheTime;
  
  // Duración del cache (5 minutos)
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Obtiene parcelas agrupadas por finca y variedad
  Future<List<ParcelaGrouped>> getParcelasGrouped({bool forceRefresh = false}) async {
    if (!forceRefresh && 
        _parcelasGroupedCache != null && 
        _lastCacheUpdate != null &&
        DateTime.now().difference(_lastCacheUpdate!) < _cacheDuration) {
      return _parcelasGroupedCache!;
    }

    try {
      final parcelas = await _parcelaService.getParcelasGrouped();
      _parcelasGroupedCache = parcelas;
      _lastCacheUpdate = DateTime.now();
      return parcelas;
    } catch (e) {
      if (_parcelasGroupedCache != null) {
        return _parcelasGroupedCache!;
      }
      throw Exception('Error al obtener parcelas agrupadas: $e');
    }
  }

  /// Obtiene lista de fincas únicas
  Future<List<String>> getFincas({bool forceRefresh = false}) async {
    if (!forceRefresh && 
        _fincasCache != null && 
        _lastCacheUpdate != null &&
        DateTime.now().difference(_lastCacheUpdate!) < _cacheDuration) {
      return _fincasCache!;
    }

    try {
      final fincas = await _parcelaService.getParcelaOptions('finca');
      _fincasCache = fincas;
      _lastCacheUpdate = DateTime.now();
      return fincas;
    } catch (e) {
      if (_fincasCache != null) {
        return _fincasCache!;
      }
      throw Exception('Error al obtener fincas: $e');
    }
  }

  /// Obtiene lista de variedades únicas
  Future<List<String>> getVariedades({bool forceRefresh = false}) async {
    if (!forceRefresh && 
        _variedadesCache != null && 
        _lastCacheUpdate != null &&
        DateTime.now().difference(_lastCacheUpdate!) < _cacheDuration) {
      return _variedadesCache!;
    }

    try {
      final variedades = await _parcelaService.getParcelaOptions('variedad');
      _variedadesCache = variedades;
      _lastCacheUpdate = DateTime.now();
      return variedades;
    } catch (e) {
      if (_variedadesCache != null) {
        return _variedadesCache!;
      }
      throw Exception('Error al obtener variedades: $e');
    }
  }

  /// Obtiene todas las parcelas sin agrupar
  Future<List<ParcelaModel>> getParcelas({bool forceRefresh = false}) async {
    if (!forceRefresh && 
        _parcelasCache != null && 
        _parcelasCacheTime != null &&
        DateTime.now().difference(_parcelasCacheTime!) < _cacheDuration) {
      return _parcelasCache!;
    }

    try {
      final parcelas = await _parcelaService.getAllParcelasRaw();
      _parcelasCache = parcelas;
      _parcelasCacheTime = DateTime.now();
      return parcelas;
    } catch (e) {
      if (_parcelasCache != null) {
        return _parcelasCache!;
      }
      throw Exception('Error al obtener parcelas: $e');
    }
  }

  /// Obtiene parcela por ID
  Future<ParcelaModel> getParcelaById(int id) async {
    try {
      return await _parcelaService.getParcelaById(id);
    } catch (e) {
      throw Exception('Error al obtener parcela: $e');
    }
  }

  /// Crea una nueva parcela
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
      final parcela = await _parcelaService.createParcela(
        finca: finca,
        propietario: propietario,
        paraje: paraje,
        poligono: poligono,
        numParcela: numParcela,
        superficie: superficie,
        numArboles: numArboles,
        variedad: variedad,
        anoPlantacion: anoPlantacion,
        situacionEspecial: situacionEspecial,
        fruto: fruto,
        distanciaAlmacenKm: distanciaAlmacenKm,
      );
      
      // Invalidar cache
      clearCache();
      
      return parcela;
    } catch (e) {
      throw Exception('Error al crear parcela: $e');
    }
  }

  /// Actualiza una parcela
  Future<ParcelaModel> updateParcela(int id, Map<String, dynamic> updates) async {
    try {
      final parcela = await _parcelaService.updateParcela(id, updates);
      
      // Invalidar cache
      clearCache();
      
      return parcela;
    } catch (e) {
      throw Exception('Error al actualizar parcela: $e');
    }
  }

  /// Elimina una parcela
  Future<void> deleteParcela(int id) async {
    try {
      await _parcelaService.deleteParcela(id);
      
      // Invalidar cache
      clearCache();
    } catch (e) {
      throw Exception('Error al eliminar parcela: $e');
    }
  }

  /// Obtiene lista de parajes únicos (opcionalmente filtrados)
  /// Nota: El filtrado se hace en el cliente ya que el API no soporta filtros en options
  Future<List<String>> getParajes({String? finca, String? variedad}) async {
    try {
      final parcelasGrouped = await getParcelasGrouped();
      
      // Extraer parajes de las parcelas agrupadas
      final Set<String> parajeFiltrados = {};
      
      for (final parcelaGroup in parcelasGrouped) {
        // Aplicar filtro de finca si existe
        if (finca != null && parcelaGroup.finca != finca) continue;
        
        // Extraer parajes de variedades
        for (final variedadInfo in parcelaGroup.variedades) {
          // Aplicar filtro de variedad si existe
          if (variedad != null && variedadInfo.variedad != variedad) continue;
          
          // Agregar parajes al set
          if (variedadInfo.parajes != null) {
            parajeFiltrados.addAll(variedadInfo.parajes!.where((p) => p.isNotEmpty));
          }
        }
      }
      
      return parajeFiltrados.toList()..sort();
    } catch (e) {
      throw Exception('Error al obtener parajes: $e');
    }
  }

  /// Obtiene lista de años de plantación únicos (opcionalmente filtrados)
  /// Nota: El filtrado se hace en el cliente ya que el API no soporta filtros en options
  Future<List<String>> getAnosPlantacion({String? finca, String? variedad, String? paraje}) async {
    try {
      final parcelasGrouped = await getParcelasGrouped();
      
      // Extraer años de plantación de las parcelas agrupadas
      final Set<String> anosPlantacionFiltrados = {};
      
      for (final parcelaGroup in parcelasGrouped) {
        // Aplicar filtro de finca si existe
        if (finca != null && parcelaGroup.finca != finca) continue;
        
        // Extraer años de plantación de variedades
        for (final variedadInfo in parcelaGroup.variedades) {
          // Aplicar filtro de variedad si existe
          if (variedad != null && variedadInfo.variedad != variedad) continue;
          
          // Aplicar filtro de paraje si existe
          if (paraje != null && 
              (variedadInfo.parajes == null || !variedadInfo.parajes!.contains(paraje))) {
            continue;
          }
          
          // Agregar año de plantación al set
          if (variedadInfo.anoPlantacion != null && variedadInfo.anoPlantacion!.isNotEmpty) {
            anosPlantacionFiltrados.add(variedadInfo.anoPlantacion!);
          }
        }
      }
      
      return anosPlantacionFiltrados.toList()..sort();
    } catch (e) {
      throw Exception('Error al obtener años de plantación: $e');
    }
  }

  /// Busca parcelas que coincidan con los criterios especificados
  /// Retorna información necesaria para identificar las parcelas seleccionadas
  /// incluyendo los IDs de las parcelas individuales que coinciden
  Future<List<Map<String, dynamic>>> findParcelasByCriteria({
    String? finca,
    String? variedad,
    String? paraje,
    String? anoPlantacion,
  }) async {
    try {
      // Obtener todas las parcelas
      final todasLasParcelas = await getParcelas();
      
      // Filtrar parcelas que coinciden con los criterios
      final parcelasFiltradas = todasLasParcelas.where((parcela) {
        bool match = true;
        if (finca != null && parcela.finca != finca) match = false;
        if (variedad != null && parcela.variedad != variedad) match = false;
        if (paraje != null && parcela.paraje != paraje) match = false;
        if (anoPlantacion != null && parcela.anoPlantacion != anoPlantacion) match = false;
        return match;
      }).toList();
      
      if (parcelasFiltradas.isEmpty) {
        return [];
      }
      
      // Calcular superficie total
      final superficieTotal = parcelasFiltradas.fold<double>(
        0.0,
        (sum, parcela) => sum + (parcela.superficie ?? 0.0),
      );
      
      // Retornar grupo con los IDs de las parcelas coincidentes
      return [{
        'finca': finca,
        'variedad': variedad,
        'paraje': paraje,
        'anoPlantacion': anoPlantacion,
        'parcelasCount': parcelasFiltradas.length,
        'superficie': superficieTotal,
        'parcelaIds': parcelasFiltradas.map((p) => p.id).toList(),
      }];
    } catch (e) {
      throw Exception('Error al buscar parcelas: $e');
    }
  }



  /// Limpia el cache
  void clearCache() {
    _parcelasGroupedCache = null;
    _parcelasCache = null;
    _fincasCache = null;
    _variedadesCache = null;
    _lastCacheUpdate = null;
    _parcelasCacheTime = null;
  }
}
