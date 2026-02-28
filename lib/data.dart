import 'package:flutter/material.dart';

// Los datos ahora se cargan dinámicamente desde los repositorios correspondientes:
// - empleadoRepository para empleados
// - vehiculoRepository para vehículos  
// - recursoRepository para recursos (materiales de tarea)
// - accesorioRepository para accesorios de vehículos
// - parcelaRepository para fincas y variedades
// - taskRepository para tipos de tareas

Map<DateTime, int> mapDays(DateTime start, DateTime end, int value) {
  final Map<DateTime, int> m = {};
  DateTime cur = DateTime(start.year, start.month, start.day);
  DateTime last = DateTime(end.year, end.month, end.day);
  while (!cur.isAfter(last)) {
    m[cur] = value;
    cur = cur.add(const Duration(days: 1));
  }
  return m;
}

// ============ MODELOS DE DATOS ============

class Empleado {
  String nombre;
  Icon foto;
  Usuario? usuario; // TODO: ESTÁ MAL LA RELACIÓN ES AL REVÉS: USUARIO TIENE EMPLEADO_ID
  String contrato; // 'fijo' or 'temporal'

  Empleado({
    required this.nombre,
    required this.foto,
    this.usuario,
    required this.contrato,
  });

  factory Empleado.fromJson(Map<String, dynamic> json) {
    return Empleado(
      nombre: json['nombre'],
      foto: const Icon(Icons.person),
      contrato: json['contrato'] ?? 'fijo',
      usuario: json['usuario'] != null ? Usuario.fromJson(json['usuario']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'contrato': contrato,
      if (usuario != null) 'usuario': usuario!.toJson(),
    };
  }
}

class Usuario {
  String nombre_usuario;
  String password;
  String email;
  String secret_code;
  String rol;

  Usuario({
    required this.nombre_usuario,
    required this.password,
    required this.email,
    required this.secret_code,
    required this.rol,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      nombre_usuario: json['nombre_usuario'],
      password: json['password'] ?? '',
      email: json['email'],
      secret_code: json['secret_code'] ?? '',
      rol: json['rol'] ?? 'empleado',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre_usuario': nombre_usuario,
      'password': password,
      'email': email,
      'secret_code': secret_code,
      'rol': rol,
    };
  }
}

class HorasEmpleado {
  int id;
  Empleado empleado;
  int tarea; // task id
  DateTime fecha;
  int horas;
  DateTime inicio;
  DateTime fin;

  HorasEmpleado({
    required this.id,
    required this.empleado,
    required this.tarea,
    required this.fecha,
    required this.horas,
    required this.inicio,
    required this.fin,
  });

  factory HorasEmpleado.fromJson(Map<String, dynamic> json) {
    return HorasEmpleado(
      id: json['id'],
      empleado: Empleado.fromJson(json['empleado']),
      tarea: json['tarea'],
      fecha: DateTime.parse(json['fecha']),
      horas: json['horas'],
      inicio: DateTime.parse(json['inicio']),
      fin: DateTime.parse(json['fin']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'empleado': empleado.toJson(),
      'tarea': tarea,
      'fecha': fecha.toIso8601String(),
      'horas': horas,
      'inicio': inicio.toIso8601String(),
      'fin': fin.toIso8601String(),
    };
  }
}

class RegistroCantidadRecursos {
  int id;
  Recurso recurso;
  int tarea; // task id
  DateTime fecha;
  int cantidad;

  RegistroCantidadRecursos({
    required this.id,
    required this.recurso,
    required this.tarea,
    required this.fecha,
    required this.cantidad,
  });

  factory RegistroCantidadRecursos.fromJson(Map<String, dynamic> json) {
    return RegistroCantidadRecursos(
      id: json['id'],
      recurso: Recurso.fromJson(json['recurso']),
      tarea: json['tarea'],
      fecha: DateTime.parse(json['fecha']),
      cantidad: json['cantidad'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recurso': recurso.toJson(),
      'tarea': tarea,
      'fecha': fecha.toIso8601String(),
      'cantidad': cantidad,
    };
  }
}

class Vehiculo {
  String nombre;
  String? matricula;
  String? tipo;
  int? accesorioId; // ID del accesorio de vehículo (remolque, arado, etc.)
  String? accesorioNombre; // Nombre del accesorio para visualización
  Map<String, int> valores;
  Icon foto = const Icon(Icons.directions_car);

  Vehiculo({
    required this.nombre,
    this.matricula,
    this.tipo,
    this.accesorioId,
    this.accesorioNombre,
    Map<String, int>? valores,
  }) : valores = valores ?? <String, int>{};

  factory Vehiculo.fromJson(Map<String, dynamic> json) {
    final rawValores = json['valores'];
    final Map<String, int> parsedValores = <String, int>{};
    if (rawValores is Map) {
      rawValores.forEach((key, value) {
        if (value is num) {
          parsedValores[key.toString()] = value.toInt();
        } else {
          parsedValores[key.toString()] = int.tryParse(value?.toString() ?? '0') ?? 0;
        }
      });
    }

    return Vehiculo(
      nombre: json['nombre'] ?? '',
      matricula: json['matricula'],
      tipo: json['tipo'],
      accesorioId: json['accesorioId'],
      accesorioNombre: json['accesorioNombre'],
      valores: parsedValores,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'matricula': matricula,
      'tipo': tipo,
      'accesorioId': accesorioId,
      'accesorioNombre': accesorioNombre,
      'valores': valores,
    };
  }
}

class Recurso {
  String nombre;
  Icon foto = const Icon(Icons.shopping_basket);
  String unidades;

  Recurso({required this.nombre, this.unidades = 'unidades'});

  factory Recurso.fromJson(Map<String, dynamic> json) {
    return Recurso(
      nombre: json['nombre'],
      unidades: json['unidades'] ?? 'unidades',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'unidades': unidades,
    };
  }
}

class Task {
  int id;
  bool isCompleted;
  String? nombre; // Nombre descriptivo de la tarea
  String? fieldName; // Finca
  String? variedad;
  String? paraje;
  String? anoPlantacion;
  List<int> parcelaIds; // IDs de parcelas seleccionadas
  String? officer;
  String? type;
  DateTime inicio;
  DateTime fin;
  List<HorasEmpleado> empleados;
  List<Vehiculo> vehiculos;
  List<RegistroCantidadRecursos> recursos;

  Task({
    required this.id,
    required this.isCompleted,
    this.nombre,
    this.fieldName,
    this.variedad,
    this.paraje,
    this.anoPlantacion,
    List<int>? parcelaIds,
    this.officer,
    this.type,
    required this.inicio,
    required this.fin,
    required this.empleados,
    required this.vehiculos,
    required this.recursos,
  }) : parcelaIds = parcelaIds ?? [];

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      isCompleted: json['isCompleted'] ?? false,
      nombre: json['nombre'],
      fieldName: json['fieldName'],
      variedad: json['variedad'],
      paraje: json['paraje'],
      anoPlantacion: json['anoPlantacion'],
      parcelaIds: (json['parcelaIds'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
      officer: json['officer'],
      type: json['type'],
      inicio: DateTime.parse(json['inicio']),
      fin: DateTime.parse(json['fin']),
      empleados: (json['empleados'] as List<dynamic>?)
              ?.map((e) => HorasEmpleado.fromJson(e))
              .toList() ??
          [],
      vehiculos: (json['vehiculos'] as List<dynamic>?)
              ?.map((v) => Vehiculo.fromJson(v))
              .toList() ??
          [],
      recursos: (json['recursos'] as List<dynamic>?)
              ?.map((r) => RegistroCantidadRecursos.fromJson(r))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isCompleted': isCompleted,
      'nombre': nombre,
      'fieldName': fieldName,
      'variedad': variedad,
      'paraje': paraje,
      'anoPlantacion': anoPlantacion,
      'parcelaIds': parcelaIds,
      'officer': officer,
      'type': type,
      'inicio': inicio.toIso8601String(),
      'fin': fin.toIso8601String(),
      'empleados': empleados.map((e) => e.toJson()).toList(),
      'vehiculos': vehiculos.map((v) => v.toJson()).toList(),
      'recursos': recursos.map((r) => r.toJson()).toList(),
    };
  }
}

// ============ DATA SINGLETON ============

class Data {
  List<Task> tasks = [];

  Data() {
    // Los datos se cargarán dinámicamente desde el API a través del TaskRepository
    // No se inicializan datos de ejemplo aquí
  }

  List<Task> getTasksForDay(DateTime day) {
    return tasks.where((task) =>
        (task.inicio.isBefore(day) || _isSameDay(task.inicio, day)) &&
        (task.fin.isAfter(day) || _isSameDay(task.fin, day))).toList();
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}

Data data = Data();

// Usuario actual - Será asignado después del login
Usuario? currentUser;