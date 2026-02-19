class EmpleadoModel {
  final int id;
  final String nombre;
  final String? foto;
  final String? cargo;
  final String? cargo2;
  final bool visible;

  EmpleadoModel({
    required this.id,
    required this.nombre,
    this.foto,
    this.cargo,
    this.cargo2,
    this.visible = true,
  });

  factory EmpleadoModel.fromJson(Map<String, dynamic> json) {
    return EmpleadoModel(
      id: json['id'],
      nombre: json['nombre'],
      foto: json['foto'],
      cargo: json['cargo'],
      cargo2: json['cargo2'],
      visible: json['visible'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'foto': foto,
      'cargo': cargo,
      'cargo2': cargo2,
      'visible': visible,
    };
  }
}

class CargoEmpleado {
  final int id;
  final String tipo;

  CargoEmpleado({
    required this.id,
    required this.tipo,
  });

  factory CargoEmpleado.fromJson(Map<String, dynamic> json) {
    return CargoEmpleado(
      id: json['id'],
      tipo: json['tipo'],
    );
  }
}
