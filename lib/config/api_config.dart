class ApiConfig {
  // Base URL de la API
  static const String baseUrl = 'http://localhost:3000';
  
  // Endpoints de autenticación
  static const String loginEndpoint = '/api/auth/login';
  static const String registerEndpoint = '/api/auth/register';
  static const String meEndpoint = '/api/auth/me';
  static const String refreshEndpoint = '/api/auth/refresh';
  static const String logoutEndpoint = '/api/auth/logout';
  
  // Endpoints de dashboard
  static const String dashboardStatsEndpoint = '/api/dashboard/stats';
  
  // Endpoints de notificaciones
  static const String notificationsListEndpoint = '/api/notifications/list';
  static const String notificationsUnreadCountEndpoint = '/api/notifications/unread-count';
  static String notificationReadEndpoint(int id) => '/api/notifications/$id/read';
  
  // Endpoints de empleados
  static const String empleadosIndexEndpoint = '/api/produccion-agricola/empleados/';
  static const String empleadosAllEndpoint = '/api/produccion-agricola/empleados/all';
  static String empleadoByIdEndpoint(int id) => '/api/produccion-agricola/empleados/$id';
  static const String empleadosNewEndpoint = '/api/produccion-agricola/empleados/new';
  static String empleadosDeleteEndpoint(int id) => '/api/produccion-agricola/empleados/$id';
  static String empleadosReactivarEndpoint(int id) => '/api/produccion-agricola/empleados/$id/reactivar';
  static const String cargosEmpleadosEndpoint = '/api/produccion-agricola/cargos-empleados';
  
  // Endpoints de nóminas
  static const String nominaCreateEndpoint = '/api/produccion-agricola/empleados/nomina';
  static String nominasByEmpleadoEndpoint(int empleadoId) => '/api/produccion-agricola/empleados/$empleadoId/nominas';
  static String nominaUpdateEndpoint(int id) => '/api/produccion-agricola/empleados/nominas/$id';
  static String nominaDeleteEndpoint(int id) => '/api/produccion-agricola/empleados/nominas/$id';
  
  // Endpoints de parcelas
  static const String parcelasIndexEndpoint = '/api/produccion-agricola/parcelas/';
  static const String parcelasAllRawEndpoint = '/api/produccion-agricola/parcelas/allRaw';
  static const String parcelasOptionsEndpoint = '/api/produccion-agricola/parcelas/options';
  static String parcelaByIdEndpoint(int id) => '/api/produccion-agricola/parcelas/$id';
  static const String parcelasNewEndpoint = '/api/produccion-agricola/parcelas/new';
  static String parcelasUpdateEndpoint(int id) => '/api/produccion-agricola/parcelas/$id';
  static String parcelasDeleteEndpoint(int id) => '/api/produccion-agricola/parcelas/$id';
  
  // Endpoints de recursos
  static const String recursosIndexEndpoint = '/api/produccion-agricola/recursos/';
  static const String recursosAllEndpoint = '/api/produccion-agricola/recursos/all';
  static const String recursosCompleteEndpoint = '/api/produccion-agricola/recursos/complete';
  static const String recursosNewEndpoint = '/api/produccion-agricola/recursos/new';
  static const String recursosPrecioEndpoint = '/api/produccion-agricola/recursos/precio';
  static String recursosPreciosByIdEndpoint(int id) => '/api/produccion-agricola/recursos/$id/precios';
  
  // Endpoints de accesorios
  static const String accesoriosIndexEndpoint = '/api/produccion-agricola/accesorios/';
  static const String accesoriosAllEndpoint = '/api/produccion-agricola/accesorios/all';
  static const String accesoriosNewEndpoint = '/api/produccion-agricola/accesorios/';
  static String accesoriosDeleteEndpoint(int id) => '/api/produccion-agricola/accesorios/$id';
  
  // Endpoints de vehículos
  static const String vehiculosIndexEndpoint = '/api/produccion-agricola/vehiculos/';
  static const String vehiculosAllEndpoint = '/api/produccion-agricola/vehiculos/all';
  static const String vehiculosNewEndpoint = '/api/produccion-agricola/vehiculos/';
  static String vehiculosDeleteEndpoint(String matricula) => '/api/produccion-agricola/vehiculos/$matricula';
  
  // Endpoints de tareas
  static const String tareasIndexEndpoint = '/api/produccion-agricola/tareas/';
  static const String tareasTiposEndpoint = '/api/produccion-agricola/tareas/tipos-tarea';
  static const String tareasCrearTipoEndpoint = '/api/produccion-agricola/tareas/crear-tipo';
  static const String tareasNewEndpoint = '/api/produccion-agricola/tarea/new';
  static String tareaByIdEndpoint(int id) => '/api/produccion-agricola/tarea/$id/';
  static String tareaUpdateEndpoint(int id) => '/api/produccion-agricola/tarea/$id/';
  static String tareaPatchEndpoint(int id) => '/api/produccion-agricola/tareas/$id';
  static String tareaDeleteEndpoint(int id) => '/api/produccion-agricola/tarea/$id/';
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
