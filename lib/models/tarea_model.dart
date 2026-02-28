class TareaModel {
  final int? id;
  final String tipoTarea;
  final String? nombre;
  final DateTime fechaInicio;
  final DateTime fechaFinal;
  final String? responsable;
  final int? idEmpleadoResponsable;
  final bool completada;
  final String? notas;
  final double? costeTotal;
  final List<ParcelaTarea>? parcelas;
  final List<GastoEmpleadoTarea>? gastosEmpleados;
  final List<GastoVehiculoTarea>? gastosVehiculos;
  final List<GastoRecursoTarea>? gastosRecursos;

  TareaModel({
    this.id,
    required this.tipoTarea,
    this.nombre,
    required this.fechaInicio,
    required this.fechaFinal,
    this.responsable,
    this.idEmpleadoResponsable,
    this.completada = false,
    this.notas,
    this.costeTotal,
    this.parcelas,
    this.gastosEmpleados,
    this.gastosVehiculos,
    this.gastosRecursos,
  });

  factory TareaModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is String && value.isNotEmpty) {
        return DateTime.parse(value);
      }
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    return TareaModel(
      id: json['id'],
      tipoTarea: json['tipo_tarea'] ?? json['tipo'] ?? '',
      nombre: json['nombre'],
      fechaInicio: parseDate(json['fecha_inicio']),
      fechaFinal: parseDate(json['fecha_final']),
      responsable: json['responsable'],
      idEmpleadoResponsable: json['id_empleado_responsable'],
      completada: json['completada'] ?? false,
      notas: json['notas'],
      costeTotal: json['coste_total']?.toDouble(),
      parcelas: json['parcelas'] != null
          ? (json['parcelas'] as List)
              .map((p) => ParcelaTarea.fromJson(p))
              .toList()
          : null,
      gastosEmpleados: json['gastos_empleados'] != null
          ? (json['gastos_empleados'] as List)
              .map((g) => GastoEmpleadoTarea.fromJson(g))
              .toList()
          : null,
      gastosVehiculos: json['gastos_vehiculos'] != null
          ? (json['gastos_vehiculos'] as List)
              .map((g) => GastoVehiculoTarea.fromJson(g))
              .toList()
          : null,
      gastosRecursos: json['gastos_recursos'] != null
          ? (json['gastos_recursos'] as List)
              .map((g) => GastoRecursoTarea.fromJson(g))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'tipo_tarea': tipoTarea,
      'nombre': nombre,
      'fecha_inicio': fechaInicio.toIso8601String().split('T')[0],
      'fecha_final': fechaFinal.toIso8601String().split('T')[0],
      'responsable': responsable,
      'id_empleado_responsable': idEmpleadoResponsable,
      'completada': completada,
      'notas': notas,
      'coste_total': costeTotal,
      if (parcelas != null)
        'parcelas': parcelas!.map((p) => p.toJson()).toList(),
      if (gastosEmpleados != null)
        'gastos_empleados': gastosEmpleados!.map((g) => g.toJson()).toList(),
      if (gastosVehiculos != null)
        'gastos_vehiculos': gastosVehiculos!.map((g) => g.toJson()).toList(),
      if (gastosRecursos != null)
        'gastos_recursos': gastosRecursos!.map((g) => g.toJson()).toList(),
    };
  }
}

class ParcelaTarea {
  final int id;
  final String? finca;
  final String? variedad;

  ParcelaTarea({required this.id, this.finca, this.variedad});

  factory ParcelaTarea.fromJson(Map<String, dynamic> json) {
    return ParcelaTarea(
      id: json['id'],
      finca: json['finca'],
      variedad: json['variedad'],
    );
  }

  Map<String, dynamic> toJson() => {'id': id};
}

class GastoEmpleadoTarea {
  final int? id;
  final int idEmpleado;
  final String? nombreEmpleado;
  final Map<String, double>? valores;

  GastoEmpleadoTarea({
    this.id,
    required this.idEmpleado,
    this.nombreEmpleado,
    this.valores,
  });

  factory GastoEmpleadoTarea.fromJson(Map<String, dynamic> json) {
    Map<String, double>? valoresMap;
    if (json['valores'] != null) {
      valoresMap = {};
      (json['valores'] as Map).forEach((key, value) {
        if (value is num) {
          valoresMap![key.toString()] = value.toDouble();
        } else {
          valoresMap![key.toString()] = double.tryParse(value?.toString() ?? '0') ?? 0;
        }
      });
    }

    return GastoEmpleadoTarea(
      id: json['id'],
      idEmpleado: json['id_empleado'] ?? json['id'] ?? 0,
      nombreEmpleado: json['nombre_empleado'] ?? json['nombre'],
      valores: valoresMap,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'id_empleado': idEmpleado,
      if (valores != null) 'valores': valores,
    };
  }
}

class GastoVehiculoTarea {
  final int? id;
  final String matricula;
  final String? nombreVehiculo;
  final String? tipoVehiculo;
  final int? idAccesorio;
  final String? nombreAccesorio;
  final Map<String, dynamic>? valores;

  GastoVehiculoTarea({
    this.id,
    required this.matricula,
    this.nombreVehiculo,
    this.tipoVehiculo,
    this.idAccesorio,
    this.nombreAccesorio,
    this.valores,
  });

  factory GastoVehiculoTarea.fromJson(Map<String, dynamic> json) {
    final accesorio = json['accesorio'];
    final vehiculo = json['vehiculo'];

    String resolveMatricula() {
      final raw = json['matricula'] ??
          json['vehiculo_matricula'] ??
          json['matricula_vehiculo'] ??
          (vehiculo is Map ? vehiculo['matricula'] : null);
      return (raw ?? '').toString();
    }

    String? resolveNombre() {
      final raw = json['nombre_vehiculo'] ??
          json['nombre'] ??
          (vehiculo is Map ? vehiculo['nombre'] : null);
      return raw?.toString();
    }

    String? resolveTipo() {
      final raw = json['tipo'] ??
          json['tipo_vehiculo'] ??
          (vehiculo is Map ? vehiculo['tipo'] : null);
      return raw?.toString();
    }

    return GastoVehiculoTarea(
      id: json['id'],
      matricula: resolveMatricula(),
      nombreVehiculo: resolveNombre(),
      tipoVehiculo: resolveTipo(),
      idAccesorio: json['id_accesorio'] ?? (accesorio is Map ? accesorio['id'] : null),
      nombreAccesorio: json['nombre_accesorio'] ?? (accesorio is Map ? accesorio['nombre'] : null),
      valores: json['valores'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'matricula': matricula,
      if (idAccesorio != null) 'id_accesorio': idAccesorio,
      if (valores != null) 'valores': valores,
    };
  }
}

class GastoRecursoTarea {
  final int? id;
  final int idRecurso;
  final String? nombreRecurso;
  final Map<String, double>? valores;

  GastoRecursoTarea({
    this.id,
    required this.idRecurso,
    this.nombreRecurso,
    this.valores,
  });

  factory GastoRecursoTarea.fromJson(Map<String, dynamic> json) {
    Map<String, double>? valoresMap;
    if (json['valores'] != null) {
      valoresMap = {};
      (json['valores'] as Map).forEach((key, value) {
        if (value is num) {
          valoresMap![key.toString()] = value.toDouble();
        } else {
          valoresMap![key.toString()] = double.tryParse(value?.toString() ?? '0') ?? 0;
        }
      });
    }

    return GastoRecursoTarea(
      id: json['id'],
      idRecurso: json['id_recurso'] ?? json['id'] ?? 0,
      nombreRecurso: json['nombre_recurso'] ?? json['nombre'],
      valores: valoresMap,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'id_recurso': idRecurso,
      if (valores != null) 'valores': valores,
    };
  }
}

class TipoTarea {
  final int id;
  final String tipo;

  TipoTarea({required this.id, required this.tipo});

  factory TipoTarea.fromJson(Map<String, dynamic> json) {
    return TipoTarea(
      id: json['id'],
      tipo: json['tipo'],
    );
  }
}
