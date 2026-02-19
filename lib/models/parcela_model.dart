class ParcelaModel {
  final int id;
  final String finca;
  final String? propietario;
  final String? paraje;
  final int? poligono;
  final String? numParcela;
  final double? superficie;
  final int? numArboles;
  final String? variedad;
  final String? anoPlantacion;
  final String? situacionEspecial;
  final String? fruto;
  final double? distanciaAlmacenKm;

  ParcelaModel({
    required this.id,
    required this.finca,
    this.propietario,
    this.paraje,
    this.poligono,
    this.numParcela,
    this.superficie,
    this.numArboles,
    this.variedad,
    this.anoPlantacion,
    this.situacionEspecial,
    this.fruto,
    this.distanciaAlmacenKm,
  });

  factory ParcelaModel.fromJson(Map<String, dynamic> json) {
    return ParcelaModel(
      id: json['id'],
      finca: json['finca'],
      propietario: json['propietario'],
      paraje: json['paraje'],
      poligono: json['poligono'],
      numParcela: json['num_parcela'],
      superficie: json['superficie']?.toDouble(),
      numArboles: json['num_arboles'],
      variedad: json['variedad'],
      anoPlantacion: json['ano_plantacion'],
      situacionEspecial: json['situacion_especial'],
      fruto: json['fruto'],
      distanciaAlmacenKm: json['distancia_almacen_km']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'finca': finca,
      'propietario': propietario,
      'paraje': paraje,
      'poligono': poligono,
      'num_parcela': numParcela,
      'superficie': superficie,
      'num_arboles': numArboles,
      'variedad': variedad,
      'ano_plantacion': anoPlantacion,
      'situacion_especial': situacionEspecial,
      'fruto': fruto,
      'distancia_almacen_km': distanciaAlmacenKm,
    };
  }
}

/// Información de variedad dentro de una finca agrupada
class VariedadInfo {
  final String variedad;
  final String? anoPlantacion;
  final double? superficie;
  final String? fruto;
  final String? situacionEspecial;
  final int? parcelasCount;
  final List<String>? parajes;

  VariedadInfo({
    required this.variedad,
    this.anoPlantacion,
    this.superficie,
    this.fruto,
    this.situacionEspecial,
    this.parcelasCount,
    this.parajes,
  });

  factory VariedadInfo.fromJson(Map<String, dynamic> json) {
    return VariedadInfo(
      variedad: json['variedad'],
      anoPlantacion: json['ano_plantacion'],
      superficie: json['superficie']?.toDouble(),
      fruto: json['fruto'],
      situacionEspecial: json['situacion_especial'],
      parcelasCount: json['parcelas_count'],
      parajes: (json['parajes'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
    );
  }
}

/// Modelo para parcelas agrupadas por finca (respuesta del endpoint /index)
class ParcelaGrouped {
  final int? id;
  final String finca;
  final double? superficieTotal;
  final int? numeroParcelas;
  final List<VariedadInfo> variedades;

  ParcelaGrouped({
    this.id,
    required this.finca,
    this.superficieTotal,
    this.numeroParcelas,
    required this.variedades,
  });

  factory ParcelaGrouped.fromJson(Map<String, dynamic> json) {
    return ParcelaGrouped(
      id: json['id'],
      finca: json['finca'],
      superficieTotal: json['superficie_total']?.toDouble(),
      numeroParcelas: json['numero_parcelas'],
      variedades: (json['variedades'] as List<dynamic>?)
              ?.map((v) => VariedadInfo.fromJson(v))
              .toList() ??
          [],
    );
  }
}
