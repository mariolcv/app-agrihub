/// Modelo para accesorios/aperos
class AccesorioModel {
  final int id;
  final String nombre;
  final String? tipo;
  final bool activo;
  final double? factorConsumo;
  final double? costeHora;

  AccesorioModel({
    required this.id,
    required this.nombre,
    this.tipo,
    this.activo = true,
    this.factorConsumo,
    this.costeHora,
  });

  factory AccesorioModel.fromJson(Map<String, dynamic> json) {
    return AccesorioModel(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      tipo: json['tipo'],
      activo: json['activo'] ?? true,
      factorConsumo: json['factor_consumo'] != null 
          ? (json['factor_consumo'] as num).toDouble() 
          : null,
      costeHora: json['coste_hora'] != null 
          ? (json['coste_hora'] as num).toDouble() 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      if (tipo != null) 'tipo': tipo,
      'activo': activo,
      if (factorConsumo != null) 'factor_consumo': factorConsumo,
      if (costeHora != null) 'coste_hora': costeHora,
    };
  }

  AccesorioModel copyWith({
    int? id,
    String? nombre,
    String? tipo,
    bool? activo,
    double? factorConsumo,
    double? costeHora,
  }) {
    return AccesorioModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      tipo: tipo ?? this.tipo,
      activo: activo ?? this.activo,
      factorConsumo: factorConsumo ?? this.factorConsumo,
      costeHora: costeHora ?? this.costeHora,
    );
  }
}
