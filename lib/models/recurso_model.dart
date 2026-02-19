/// Modelo para recursos (fertilizantes, pesticidas, etc.)
class RecursoModel {
  final int id;
  final String nombre;
  final String? foto;
  final String? tipoTarea;
  final String unidadConsumo;
  final double? precioActual;
  final String? fechaPrecioActual;
  final double? materiaActiva;
  final Map<String, dynamic>? valores;

  RecursoModel({
    required this.id,
    required this.nombre,
    this.foto,
    this.tipoTarea,
    required this.unidadConsumo,
    this.precioActual,
    this.fechaPrecioActual,
    this.materiaActiva,
    this.valores,
  });

  factory RecursoModel.fromJson(Map<String, dynamic> json) {
    return RecursoModel(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      foto: json['foto'],
      tipoTarea: json['tipo_tarea'],
      unidadConsumo: json['unidad_consumo'] ?? 'unidades',
      precioActual: json['precio_actual'] != null 
          ? (json['precio_actual'] as num).toDouble() 
          : null,
      fechaPrecioActual: json['fecha_precio_actual'],
      materiaActiva: json['materia_activa'] != null 
          ? (json['materia_activa'] as num).toDouble() 
          : null,
      valores: json['valores'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      if (foto != null) 'foto': foto,
      if (tipoTarea != null) 'tipo_tarea': tipoTarea,
      'unidad_consumo': unidadConsumo,
      if (precioActual != null) 'precio_actual': precioActual,
      if (fechaPrecioActual != null) 'fecha_precio_actual': fechaPrecioActual,
      if (materiaActiva != null) 'materia_activa': materiaActiva,
      if (valores != null) 'valores': valores,
    };
  }

  RecursoModel copyWith({
    int? id,
    String? nombre,
    String? foto,
    String? tipoTarea,
    String? unidadConsumo,
    double? precioActual,
    String? fechaPrecioActual,
    double? materiaActiva,
    Map<String, dynamic>? valores,
  }) {
    return RecursoModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      foto: foto ?? this.foto,
      tipoTarea: tipoTarea ?? this.tipoTarea,
      unidadConsumo: unidadConsumo ?? this.unidadConsumo,
      precioActual: precioActual ?? this.precioActual,
      fechaPrecioActual: fechaPrecioActual ?? this.fechaPrecioActual,
      materiaActiva: materiaActiva ?? this.materiaActiva,
      valores: valores ?? this.valores,
    );
  }
}
