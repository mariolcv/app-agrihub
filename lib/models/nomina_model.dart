class NominaModel {
  final int id;
  final int idEmpleado;
  final int anio;
  final int mes;
  final double salarioBruto;
  final double horasTrabajadas;
  final double costePorHora;
  final String? empleadoNombre;

  NominaModel({
    required this.id,
    required this.idEmpleado,
    required this.anio,
    required this.mes,
    required this.salarioBruto,
    required this.horasTrabajadas,
    required this.costePorHora,
    this.empleadoNombre,
  });

  factory NominaModel.fromJson(Map<String, dynamic> json) {
    return NominaModel(
      id: json['id'],
      idEmpleado: json['id_empleado'],
      anio: json['anio'],
      mes: json['mes'],
      salarioBruto: (json['salario_bruto'] ?? 0).toDouble(),
      horasTrabajadas: (json['horas_trabajadas'] ?? 0).toDouble(),
      costePorHora: (json['coste_por_hora'] ?? 0).toDouble(),
      empleadoNombre: json['empleado_nombre'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_empleado': idEmpleado,
      'anio': anio,
      'mes': mes,
      'salario_bruto': salarioBruto,
      'horas_trabajadas': horasTrabajadas,
      'coste_por_hora': costePorHora,
    };
  }

  String get mesNombre {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return meses[mes - 1];
  }
}
