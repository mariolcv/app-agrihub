import 'package:flutter/material.dart';
import 'package:intl/intl.dart';



String getStringDate(DateTime fechaSeleccionada) {
  final DateTime hoy = DateTime.now();
  final DateTime manana = hoy.add(const Duration(days: 1));
  final DateTime ayer = hoy.subtract(const Duration(days: 1));

  // Mapas para traducir los días de la semana y los meses al español
  const List<String> diasSemana = [
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado',
    'domingo'
  ];
  const List<String> meses = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre'
  ];

  // Obtener el día de la semana y el mes
  String diaSemana = diasSemana[fechaSeleccionada.weekday - 1];
  String mes = meses[fechaSeleccionada.month - 1];

  // Determinar el prefijo (Hoy, Mañana, Ayer o vacío)
  String prefijo = '';
  if (DateUtils.isSameDay(fechaSeleccionada, hoy)) {
    prefijo = 'Hoy,';
  } else if (DateUtils.isSameDay(fechaSeleccionada, manana)) {
    prefijo = 'Mañana,';
  } else if (DateUtils.isSameDay(fechaSeleccionada, ayer)) {
    prefijo = 'Ayer,';
  }

  // Formatear la fecha
  return '$prefijo ${diaSemana[0].toUpperCase()}${diaSemana.substring(1)} ${fechaSeleccionada.day} de $mes';
}



String tituloTareas(DateTime diaSeleccionado) {
  return "Tareas del ${DateFormat('d MMMM', 'es_ES').format(diaSeleccionado)}";
}