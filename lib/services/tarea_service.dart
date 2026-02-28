import '../config/api_config.dart';
import '../models/tarea_model.dart';
import 'api_service.dart';

class TareaService {
  final ApiService _apiService = ApiService();

  Map<String, dynamic> _extractTaskPayload(Map<String, dynamic> response) {
    dynamic current = response;

    for (int depth = 0; depth < 5; depth++) {
      if (current is! Map<String, dynamic>) {
        break;
      }

      final hasTaskFields = current.containsKey('fecha_inicio') ||
          current.containsKey('fecha_final') ||
          current.containsKey('tipo_tarea') ||
          current.containsKey('parcelas') ||
          current.containsKey('gastos_empleados') ||
          current.containsKey('gastos_vehiculos') ||
          current.containsKey('gastos_recursos');

      if (hasTaskFields) {
        return current;
      }

      if (current.containsKey('data')) {
        current = current['data'];
        continue;
      }

      if (current.containsKey('tarea')) {
        current = current['tarea'];
        continue;
      }

      break;
    }

    if (current is Map<String, dynamic>) {
      return current;
    }

    throw Exception('Formato inesperado del payload de tarea: ${current.runtimeType}');
  }

  // Obtener tareas con filtros
  Future<List<TareaModel>> getTareas({
    required DateTime fechaDesde,
    required DateTime fechaHasta,
    String? responsable,
    String? tipo,
    List<int>? parcelaIds,
  }) async {
    try {
      final queryParams = <String, String>{
        'fecha_desde': fechaDesde.toIso8601String().split('T')[0],
        'fecha_hasta': fechaHasta.toIso8601String().split('T')[0],
      };

      if (responsable != null && responsable.isNotEmpty) {
        queryParams['responsable'] = responsable;
      }
      if (tipo != null && tipo.isNotEmpty) {
        queryParams['tipo'] = tipo;
      }
      if (parcelaIds != null && parcelaIds.isNotEmpty) {
        queryParams['parcela_ids'] = parcelaIds.toString();
      }

      print('📋 [TareaService.getTareas] Obteniendo tareas');
      print('   Rango: $fechaDesde - $fechaHasta');
      print('   Endpoint: ${ApiConfig.tareasIndexEndpoint}');

      final response = await _apiService.get(
        ApiConfig.tareasIndexEndpoint,
        queryParameters: queryParams,
      );

      print('📦 [TareaService.getTareas] Respuesta recibida:');
      print('   Keys: ${response.keys}');

      final List<dynamic> tareasJson = response['data'] ?? response['tareas'] ?? [];
      print('   📊 Total tareas: ${tareasJson.length}');
      
      if (tareasJson.isNotEmpty) {
        print('   🔍 Examinando primera tarea:');
        final primeraTarea = tareasJson.first;
        print('      Keys: ${primeraTarea.keys}');
        print('      gastos_empleados: ${primeraTarea['gastos_empleados']?.runtimeType} - ${primeraTarea['gastos_empleados']?.length ?? 0} items');
        print('      gastos_vehiculos: ${primeraTarea['gastos_vehiculos']?.runtimeType} - ${primeraTarea['gastos_vehiculos']?.length ?? 0} items');
        print('      gastos_recursos: ${primeraTarea['gastos_recursos']?.runtimeType} - ${primeraTarea['gastos_recursos']?.length ?? 0} items');
      }
      
      return tareasJson.map((json) => TareaModel.fromJson(json)).toList();
    } catch (e) {
      print('❌ [TareaService.getTareas] Error: $e');
      throw Exception('Error al obtener tareas: $e');
    }
  }

  // Obtener tareas con DETALLES COMPLETOS (gastos_empleados, gastos_vehiculos, gastos_recursos)
  // ⚠️ Hace una llamada individual por cada tarea - usar solo cuando sea necesario
  Future<List<TareaModel>> getTareasWithDetails({
    required DateTime fechaDesde,
    required DateTime fechaHasta,
    String? responsable,
    String? tipo,
    List<int>? parcelaIds,
  }) async {
    try {
      print('📋 [TareaService.getTareasWithDetails] Obteniendo tareas CON detalles completos');
      print('   Rango: $fechaDesde - $fechaHasta');
      
      // Paso 1: Obtener lista básica de tareas
      final tareasBasicas = await getTareas(
        fechaDesde: fechaDesde,
        fechaHasta: fechaHasta,
        responsable: responsable,
        tipo: tipo,
        parcelaIds: parcelaIds,
      );
      
      print('   📊 Tareas básicas obtenidas: ${tareasBasicas.length}');
      
      if (tareasBasicas.isEmpty) {
        print('   ℹ️ No hay tareas para cargar detalles');
        return [];
      }
      
      // Paso 2: Cargar detalles completos de cada tarea
      print('   🔄 Cargando detalles individuales de ${tareasBasicas.length} tareas...');
      final tareasCompletas = <TareaModel>[];
      
      for (var i = 0; i < tareasBasicas.length; i++) {
        final tareaBasica = tareasBasicas[i];
        if (tareaBasica.id != null) {
          try {
            print('      [$i/${tareasBasicas.length}] Cargando tarea ID ${tareaBasica.id}...');
            final tareaCompleta = await getTareaById(tareaBasica.id!);
            tareasCompletas.add(tareaCompleta);
          } catch (e) {
            print('      ⚠️ Error cargando tarea ${tareaBasica.id}: $e');
            // Si falla una tarea individual, agregar la básica sin detalles
            tareasCompletas.add(tareaBasica);
          }
        } else {
          // Si no tiene ID, agregar la básica
          tareasCompletas.add(tareaBasica);
        }
      }
      
      print('   ✅ Tareas completas cargadas: ${tareasCompletas.length}');
      return tareasCompletas;
    } catch (e) {
      print('❌ [TareaService.getTareasWithDetails] Error: $e');
      throw Exception('Error al obtener tareas con detalles: $e');
    }
  }

  // Obtener tarea por ID
  Future<TareaModel> getTareaById(int id) async {
    try {
      print('🔍 [TareaService.getTareaById] Obteniendo tarea ID: $id');
      print('   Endpoint: ${ApiConfig.tareaByIdEndpoint(id)}');
      
      final response = await _apiService.get(
        ApiConfig.tareaByIdEndpoint(id),
      );

      print('📦 [TareaService.getTareaById] Respuesta recibida:');
      print('   Keys: ${response.keys}');
      print('   Tiene campo tarea: ${response.containsKey('tarea')}');
      print('   Tiene campo data: ${response.containsKey('data')}');
      
      final tareaData = _extractTaskPayload(response);
      print('   📋 Campo tarea keys: ${tareaData.keys}');
      print('   📋 gastos_empleados: ${tareaData['gastos_empleados']?.runtimeType} - ${tareaData['gastos_empleados']?.length ?? 0} items');
      print('   📋 gastos_vehiculos: ${tareaData['gastos_vehiculos']?.runtimeType} - ${tareaData['gastos_vehiculos']?.length ?? 0} items');
      print('   📋 gastos_recursos: ${tareaData['gastos_recursos']?.runtimeType} - ${tareaData['gastos_recursos']?.length ?? 0} items');
      
      if (tareaData['gastos_empleados'] != null && tareaData['gastos_empleados'] is List) {
        final gastos = tareaData['gastos_empleados'] as List;
        print('   👥 Detalles gastos_empleados:');
        for (var i = 0; i < gastos.length; i++) {
          print('      [$i] ${gastos[i].runtimeType}: ${gastos[i]}');
        }
      }
      
      return TareaModel.fromJson(tareaData);
    } catch (e) {
      print('❌ [TareaService.getTareaById] Error: $e');
      throw Exception('Error al obtener tarea: $e');
    }
  }

  // Crear tarea
  // Retorna el ID de la tarea creada
  Future<int> createTarea(TareaModel tarea) async {
    try {
      final response = await _apiService.post(
        ApiConfig.tareasNewEndpoint,
        body: tarea.toJson(),
      );

      // El backend devuelve {success: true, message: "...", tarea_id: 125}
      return response['tarea_id'] as int;
    } catch (e) {
      throw Exception('Error al crear tarea: $e');
    }
  }

  // Crear tarea desde payload crudo
  // Útil cuando ya tenemos el payload en el formato correcto del API
  Future<int> createTareaFromPayload(Map<String, dynamic> payload) async {
    try {
      print('🔧 [TareaService] Enviando payload al API:');
      print('   Endpoint: ${ApiConfig.tareasNewEndpoint}');
      print('   Payload keys: ${payload.keys.toList()}');
      
      final response = await _apiService.post(
        ApiConfig.tareasNewEndpoint,
        body: payload,
      );

      print('🔧 [TareaService] Respuesta recibida del API:');
      print('   Response type: ${response.runtimeType}');
      print('   Response keys: ${response.keys.toList()}');
      print('   Response completo: $response');
      
      // Intentar extraer el ID de la tarea en diferentes formatos posibles
      if (response.containsKey('tarea_id')) {
        // Formato: {tarea_id: 123}
        final tareaId = response['tarea_id'];
        print('   ✅ tarea_id encontrado: $tareaId (tipo: ${tareaId.runtimeType})');
        return tareaId as int;
      } else if (response.containsKey('data') && response['data'] is Map) {
        // Formato: {success: true, message: "...", data: {id: 123, ...}}
        final data = response['data'] as Map<String, dynamic>;
        if (data.containsKey('id')) {
          final tareaId = data['id'];
          print('   ✅ ID encontrado en data.id: $tareaId (tipo: ${tareaId.runtimeType})');
          // El ID puede venir como String o int
          return tareaId is int ? tareaId : int.parse(tareaId.toString());
        }
      } else if (response.containsKey('tarea')) {
        // Formato: {tarea: {id: 123, ...}}
        print('   ⚠️ Backend devolvió objeto "tarea" completo en lugar de solo ID');
        print('   Contenido de tarea: ${response['tarea']}');
        if (response['tarea'] is Map && response['tarea']['id'] != null) {
          final tareaId = response['tarea']['id'];
          return tareaId is int ? tareaId : int.parse(tareaId.toString());
        }
      }
      
      throw Exception('Respuesta del backend no contiene ID de tarea: $response');
    } catch (e, stackTrace) {
      print('❌ [TareaService] ERROR en createTareaFromPayload:');
      print('   Error: $e');
      print('   Tipo: ${e.runtimeType}');
      print('   Stack trace (primeras 5 líneas):');
      print(stackTrace.toString().split('\n').take(5).join('\n'));
      rethrow;
    }
  }

  // Actualizar tarea completa
  // Retorna el ID de la tarea actualizada
  Future<int> updateTarea(int id, TareaModel tarea) async {
    try {
      final response = await _apiService.put(
        ApiConfig.tareaUpdateEndpoint(id),
        body: tarea.toJson(),
      );

      // El backend probablemente devuelve estructura similar al create
      return response['tarea_id'] as int? ?? id;
    } catch (e) {
      throw Exception('Error al actualizar tarea: $e');
    }
  }

  // Actualizar tarea desde payload crudo
  Future<int> updateTareaFromPayload(int id, Map<String, dynamic> payload) async {
    try {
      final response = await _apiService.put(
        ApiConfig.tareaUpdateEndpoint(id),
        body: payload,
      );

      return response['tarea_id'] as int? ?? id;
    } catch (e) {
      throw Exception('Error al actualizar tarea: $e');
    }
  }

  // Actualización parcial (PATCH)
  Future<TareaModel> patchTarea(int id, Map<String, dynamic> updates) async {
    try {
      print('🔧 [TareaService.patchTarea] PATCH tarea $id con updates: $updates');
      print('   Endpoint: ${ApiConfig.tareaPatchEndpoint(id)}');
      
      final response = await _apiService.patch(
        ApiConfig.tareaPatchEndpoint(id),
        body: updates,
      );

      print('✅ [TareaService.patchTarea] Respuesta recibida:');
      print('   Keys: ${response.keys}');
      print('   Tiene campo tarea: ${response.containsKey('tarea')}');
      print('   Tiene campo data: ${response.containsKey('data')}');
      
      // Manejar diferentes formatos de respuesta
      final tareaData = _extractTaskPayload(response);
      
      print('   📦 Parseando tarea desde: ${tareaData.keys}');
      return TareaModel.fromJson(tareaData);
    } catch (e) {
      print('❌ [TareaService.patchTarea] Error: $e');
      throw Exception('Error al actualizar tarea: $e');
    }
  }

  // Eliminar tarea
  Future<void> deleteTarea(int id) async {
    try {
      await _apiService.delete(
        ApiConfig.tareaDeleteEndpoint(id),
      );
    } catch (e) {
      throw Exception('Error al eliminar tarea: $e');
    }
  }

  // Obtener tipos de tarea
  Future<List<TipoTarea>> getTiposTarea() async {
    try {
      final response = await _apiService.get(
        ApiConfig.tareasTiposEndpoint,
      );

      final List<dynamic> tiposJson = response['data'] ?? response['tipos'] ?? [];
      
      // La API devuelve strings simples, convertirlos a TipoTarea
      return tiposJson.asMap().entries.map((entry) {
        if (entry.value is String) {
          // Si es string, crear TipoTarea con índice como id
          return TipoTarea(id: entry.key, tipo: entry.value as String);
        } else {
          // Si es objeto, usar fromJson
          return TipoTarea.fromJson(entry.value);
        }
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener tipos de tarea: $e');
    }
  }

  // Crear tipo de tarea
  Future<String> createTipoTarea(String nombre) async {
    try {
      final response = await _apiService.post(
        ApiConfig.tareasCrearTipoEndpoint,
        body: {'nombre': nombre},
      );

      final data = response['data'] ?? response;
      return data['nombre'] ?? nombre;
    } catch (e) {
      throw Exception('Error al crear tipo de tarea: $e');
    }
  }
}
