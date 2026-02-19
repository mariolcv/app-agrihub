/// Modelo para vehículos
class VehiculoModel {
  final int id;
  final String matricula;
  final String nombre;
  final String tipo;
  final String marca;
  final String modelo;
  final String combustible;
  final String? foto;
  final double? consumoLHora;
  final double? consumoLKm;
  final Map<String, dynamic>? valores;

  VehiculoModel({
    required this.id,
    required this.matricula,
    required this.nombre,
    required this.tipo,
    required this.marca,
    required this.modelo,
    required this.combustible,
    this.foto,
    this.consumoLHora,
    this.consumoLKm,
    this.valores,
  });

  factory VehiculoModel.fromJson(Map<String, dynamic> json) {
    return VehiculoModel(
      id: json['id'] ?? 0,
      matricula: json['matricula'] ?? '',
      nombre: json['nombre'] ?? '',
      tipo: json['tipo'] ?? 'agrícola',
      marca: json['marca'] ?? '',
      modelo: json['modelo'] ?? '',
      combustible: json['combustible'] ?? 'diesel',
      foto: json['foto'],
      consumoLHora: json['consumo_l_hora'] != null 
          ? (json['consumo_l_hora'] as num).toDouble() 
          : null,
      consumoLKm: json['consumo_l_km'] != null 
          ? (json['consumo_l_km'] as num).toDouble() 
          : null,
      valores: json['valores'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matricula': matricula,
      'nombre': nombre,
      'tipo': tipo,
      'marca': marca,
      'modelo': modelo,
      'combustible': combustible,
      if (foto != null) 'foto': foto,
      if (consumoLHora != null) 'consumo_l_hora': consumoLHora,
      if (consumoLKm != null) 'consumo_l_km': consumoLKm,
      if (valores != null) 'valores': valores,
    };
  }

  VehiculoModel copyWith({
    int? id,
    String? matricula,
    String? nombre,
    String? tipo,
    String? marca,
    String? modelo,
    String? combustible,
    String? foto,
    double? consumoLHora,
    double? consumoLKm,
    Map<String, dynamic>? valores,
  }) {
    return VehiculoModel(
      id: id ?? this.id,
      matricula: matricula ?? this.matricula,
      nombre: nombre ?? this.nombre,
      tipo: tipo ?? this.tipo,
      marca: marca ?? this.marca,
      modelo: modelo ?? this.modelo,
      combustible: combustible ?? this.combustible,
      foto: foto ?? this.foto,
      consumoLHora: consumoLHora ?? this.consumoLHora,
      consumoLKm: consumoLKm ?? this.consumoLKm,
      valores: valores ?? this.valores,
    );
  }
}
