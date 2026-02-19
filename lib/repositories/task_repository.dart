import '../data.dart';
import '../services/tarea_service.dart';
import '../mappers/task_mapper.dart';

/// Repository para gestión de tareas
/// Implementa el patrón Repository y Singleton para centralizar el acceso a datos
/// Proporciona cache en memoria para optimizar las llamadas al API
class TaskRepository {
  // Patrón Singleton
  static final TaskRepository _instance = TaskRepository._internal();
  factory TaskRepository() => _instance;
  TaskRepository._internal();

  final TareaService _tareaService = TareaService();
  
  // Cache de tareas por mes (key: "YYYY-MM")
  final Map<String, List<Task>> _taskCache = {};
  
  // Cache de tareas individuales por ID
  final Map<int, Task> _taskByIdCache = {};

  /// Obtiene las tareas para un día específico
  /// Carga el mes completo si no está en caché
  Future<List<Task>> getTasksForDay(DateTime day) async {
    final monthKey = _getMonthKey(day);
    
    // Si no está en cache, cargar el mes completo
    if (!_taskCache.containsKey(monthKey)) {
      await _loadTasksForMonth(day.year, day.month);
    }
    
    final tasksInMonth = _taskCache[monthKey] ?? [];
    
    // Filtrar solo las tareas de ese día
    return tasksInMonth.where((task) =>
      (task.inicio.isBefore(day) || _isSameDay(task.inicio, day)) &&
      (task.fin.isAfter(day) || _isSameDay(task.fin, day))
    ).toList();
  }

  /// Obtiene las tareas para un rango de fechas
  Future<List<Task>> getTasksForDateRange(DateTime start, DateTime end) async {
    try {
      final tareaModels = await _tareaService.getTareas(
        fechaDesde: start,
        fechaHasta: end,
      );
      
      final tasks = TaskMapper.toTaskList(tareaModels);
      
      // Actualizar cache con las tareas obtenidas
      _updateCacheWithTasks(tasks);
      
      return tasks;
    } catch (e) {
      throw Exception('Error al obtener tareas: $e');
    }
  }

  /// Obtiene las tareas para un rango de fechas CON DETALLES COMPLETOS
  /// (incluye gastos_empleados, gastos_vehiculos, gastos_recursos)
  /// ⚠️ Más lento porque carga cada tarea individualmente
  Future<List<Task>> getTasksForDateRangeWithDetails(DateTime start, DateTime end) async {
    try {
      print('📋 [TaskRepository] Obteniendo tareas con detalles para rango: $start - $end');
      
      final tareaModels = await _tareaService.getTareasWithDetails(
        fechaDesde: start,
        fechaHasta: end,
      );
      
      print('📦 [TaskRepository] Mapeando ${tareaModels.length} tareas con detalles...');
      final tasks = TaskMapper.toTaskList(tareaModels);
      
      print('✅ [TaskRepository] Tareas mapeadas:');
      for (var task in tasks) {
        print('   Tarea ID ${task.id}:');
        print('     - Empleados: ${task.empleados.length}');
        print('     - Vehículos: ${task.vehiculos.length}');
        print('     - Recursos: ${task.recursos.length}');
      }
      
      // Actualizar cache con las tareas obtenidas
      _updateCacheWithTasks(tasks);
      
      return tasks;
    } catch (e) {
      print('❌ [TaskRepository.getTasksForDateRangeWithDetails] Error: $e');
      throw Exception('Error al obtener tareas con detalles: $e');
    }
  }

  /// Obtiene una tarea por ID con DETALLES COMPLETOS
  /// ⚠️ SIEMPRE consulta el API (no usa cache) porque se usa para ver/editar
  /// y necesita gastos_empleados, gastos_vehiculos, gastos_recursos
  Future<Task> getTaskById(int id) async {
    try {
      print('🔍 [TaskRepository.getTaskById] Cargando tarea ID $id DESDE API (sin cache)');
      
      // ✅ SIEMPRE llamar al API para obtener datos completos
      final tareaModel = await _tareaService.getTareaById(id);
      final task = TaskMapper.toTask(tareaModel);
      
      print('✅ [TaskRepository.getTaskById] Tarea cargada:');
      print('   - Empleados: ${task.empleados.length}');
      print('   - Vehículos: ${task.vehiculos.length}');
      print('   - Recursos: ${task.recursos.length}');
      
      // NO guardar en _taskByIdCache porque es una tarea COMPLETA
      // El cache solo debe tener tareas BÁSICAS de las listas
      
      return task;
    } catch (e) {
      print('❌ [TaskRepository.getTaskById] Error: $e');
      throw Exception('Error al obtener tarea: $e');
    }
  }

  /// Crea una nueva tarea
  Future<Task> createTask(Task task, {int? parcelaId}) async {
    try {
      final tareaModel = TaskMapper.toTareaModel(task, parcelaId: parcelaId);
      final tareaId = await _tareaService.createTarea(tareaModel);
      
      print('✅ [TaskRepository] Tarea creada con ID: $tareaId');
      print('   Recargando tarea completa desde backend...');
      
      // Invalidar cache del mes de la tarea
      _invalidateMonthCache(task.inicio);
      if (!_isSameMonth(task.inicio, task.fin)) {
        _invalidateMonthCache(task.fin);
      }
      
      // Recargar la tarea completa desde el backend con todos los datos relacionados
      final createdTask = await getTaskById(tareaId);
      print('✅ [TaskRepository] Tarea recargada:');
      print('   Empleados: ${createdTask.empleados.length}');
      print('   Vehículos: ${createdTask.vehiculos.length}');
      print('   Recursos: ${createdTask.recursos.length}');
      
      return createdTask;
    } catch (e) {
      print('❌ [TaskRepository.createTask] Error: $e');
      throw Exception('Error al crear tarea: $e');
    }
  }

  /// Actualiza una tarea existente
  Future<Task> updateTask(Task task, {int? parcelaId}) async {
    try {
      if (task.id == 0) {
        throw Exception('El ID de la tarea debe ser válido para actualizar');
      }
      
      print('🔄 [TaskRepository] Actualizando tarea ID: ${task.id}');
      
      final tareaModel = TaskMapper.toTareaModel(task, parcelaId: parcelaId);
      await _tareaService.updateTarea(task.id, tareaModel);
      
      print('✅ [TaskRepository] Tarea actualizada');
      print('   Recargando tarea completa desde backend...');
      
      // Invalidar cache
      _taskByIdCache.remove(task.id);
      _invalidateMonthCache(task.inicio);
      if (!_isSameMonth(task.inicio, task.fin)) {
        _invalidateMonthCache(task.fin);
      }
      
      // Recargar la tarea completa desde el backend con todos los datos relacionados
      final updatedTask = await getTaskById(task.id);
      print('✅ [TaskRepository] Tarea recargada:');
      print('   Empleados: ${updatedTask.empleados.length}');
      print('   Vehículos: ${updatedTask.vehiculos.length}');
      print('   Recursos: ${updatedTask.recursos.length}');
      
      return updatedTask;
    } catch (e) {
      print('❌ [TaskRepository.updateTask] Error: $e');
      throw Exception('Error al actualizar tarea: $e');
    }
  }

  /// Actualiza campos específicos de una tarea (PATCH)
  Future<Task> patchTask(int id, Map<String, dynamic> updates) async {
    try {
      final updatedTareaModel = await _tareaService.patchTarea(id, updates);
      final updatedTask = TaskMapper.toTask(updatedTareaModel);
      
      // Invalidar cache
      _taskByIdCache.remove(id);
      _invalidateMonthCache(updatedTask.inicio);
      if (!_isSameMonth(updatedTask.inicio, updatedTask.fin)) {
        _invalidateMonthCache(updatedTask.fin);
      }
      
      return updatedTask;
    } catch (e) {
      throw Exception('Error al actualizar tarea: $e');
    }
  }

  /// Marca una tarea como completada o no completada
  Future<Task> toggleTaskCompletion(int id, bool completed) async {
    return await patchTask(id, {'completada': completed});
  }

  /// Obtiene los tipos de tarea disponibles
  Future<List<String>> getTiposTarea() async {
    try {
      final tipos = await _tareaService.getTiposTarea();
      return tipos.map((t) => t.tipo).toList();
    } catch (e) {
      throw Exception('Error al obtener tipos de tarea: $e');
    }
  }

  /// Elimina una tarea por ID
  /// Limpia el cache automáticamente después de la eliminación
  Future<void> deleteTask(int id) async {
    try {
      await _tareaService.deleteTarea(id);
      
      // Limpiar del cache por ID
      _taskByIdCache.remove(id);
      
      // Limpiar de todos los meses en cache
      for (var monthKey in _taskCache.keys) {
        _taskCache[monthKey]!.removeWhere((task) => task.id == id);
      }
    } catch (e) {
      throw Exception('Error al eliminar tarea: $e');
    }
  }

  /// Limpia completamente el cache
  void clearCache() {
    _taskCache.clear();
    _taskByIdCache.clear();
  }

  /// Limpia el cache de un mes específico
  void _invalidateMonthCache(DateTime date) {
    final monthKey = _getMonthKey(date);
    _taskCache.remove(monthKey);
  }

  /// Carga las tareas de un mes completo
  Future<void> _loadTasksForMonth(int year, int month) async {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0);
    
    try {
      final tasks = await getTasksForDateRange(startOfMonth, endOfMonth);
      final monthKey = _getMonthKey(startOfMonth);
      _taskCache[monthKey] = tasks;
    } catch (e) {
      // En caso de error, guardar lista vacía para evitar reintentos constantes
      final monthKey = _getMonthKey(startOfMonth);
      _taskCache[monthKey] = [];
      rethrow;
    }
  }

  /// Actualiza el cache con una lista de tareas
  void _updateCacheWithTasks(List<Task> tasks) {
    for (var task in tasks) {
      // Actualizar cache por ID
      _taskByIdCache[task.id] = task;
      
      // Actualizar cache por mes
      final monthKey = _getMonthKey(task.inicio);
      if (_taskCache.containsKey(monthKey)) {
        // Eliminar la versión anterior si existe
        _taskCache[monthKey]!.removeWhere((t) => t.id == task.id);
        // Añadir la nueva versión
        _taskCache[monthKey]!.add(task);
      }
      
      // Si la tarea abarca múltiples meses, actualizar todos
      if (!_isSameMonth(task.inicio, task.fin)) {
        final endMonthKey = _getMonthKey(task.fin);
        if (_taskCache.containsKey(endMonthKey)) {
          _taskCache[endMonthKey]!.removeWhere((t) => t.id == task.id);
          _taskCache[endMonthKey]!.add(task);
        }
      }
    }
  }

  /// Genera la clave de cache para un mes
  String _getMonthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  /// Comprueba si dos fechas están en el mismo día
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// Comprueba si dos fechas están en el mismo mes
  bool _isSameMonth(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month;
  }
}
