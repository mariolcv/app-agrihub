import '../models/tarea_model.dart';
import '../data.dart';
import 'package:flutter/material.dart';

/// Mapper para convertir entre TareaModel (API) y Task (UI local)
/// Implementa el patrón Mapper para separar la capa de datos de la capa de presentación
class TaskMapper {
  /// Convierte un TareaModel del API a un Task para la UI
  static Task toTask(TareaModel tareaModel) {
    // Convertir gastosEmpleados a HorasEmpleado
    List<HorasEmpleado> horasEmpleados = [];
    if (tareaModel.gastosEmpleados != null) {
      int heId = 0;
      for (var gastoEmpleado in tareaModel.gastosEmpleados!) {
        // Procesar cada día en valores (formato: "YYYY-MM-DD": horas)
        if (gastoEmpleado.valores != null) {
          gastoEmpleado.valores!.forEach((fechaStr, horas) {
            try {
              DateTime fecha = DateTime.parse(fechaStr);
              // Crear un empleado básico para la UI
              Empleado empleado = Empleado(
                nombre: gastoEmpleado.nombreEmpleado ?? 'Empleado ${gastoEmpleado.idEmpleado}',
                foto: const Icon(Icons.person),
                contrato: 'fijo', // Por defecto, podría venir del API
                // Crear usuario con el nombre del empleado para las comparaciones de horas trabajadas
                usuario: gastoEmpleado.nombreEmpleado != null
                    ? Usuario(
                        nombre_usuario: gastoEmpleado.nombreEmpleado!,
                        password: '',
                        email: '',
                        secret_code: '',
                        rol: 'empleado',
                      )
                    : null,
              );
              
              horasEmpleados.add(HorasEmpleado(
                id: heId++,
                empleado: empleado,
                tarea: tareaModel.id ?? 0,
                fecha: fecha,
                horas: horas.toInt(),
                inicio: DateTime(fecha.year, fecha.month, fecha.day, 9, 0),
                fin: DateTime(fecha.year, fecha.month, fecha.day, 9 + horas.toInt(), 0),
              ));
            } catch (e) {
              print('Error parsing fecha in gastoEmpleado: $e');
            }
          });
        }
      }
    }

    // Convertir gastosVehiculos a List<Vehiculo>
    List<Vehiculo> vehiculos = [];
    if (tareaModel.gastosVehiculos != null) {
      Set<String> matriculasVistas = {};
      for (var gastoVehiculo in tareaModel.gastosVehiculos!) {
        if (!matriculasVistas.contains(gastoVehiculo.matricula)) {
          vehiculos.add(Vehiculo(
            nombre: gastoVehiculo.matricula, // Usar matricula como nombre por defecto
            matricula: gastoVehiculo.matricula,
          ));
          matriculasVistas.add(gastoVehiculo.matricula);
        }
      }
    }

    // Convertir gastosRecursos a List<RegistroCantidadRecursos>
    List<RegistroCantidadRecursos> recursos = [];
    if (tareaModel.gastosRecursos != null) {
      int raId = 0;
      for (var gastoRecurso in tareaModel.gastosRecursos!) {
        if (gastoRecurso.valores != null) {
          gastoRecurso.valores!.forEach((fechaStr, cantidad) {
            try {
              DateTime fecha = DateTime.parse(fechaStr);
              recursos.add(RegistroCantidadRecursos(
                id: raId++,
                recurso: Recurso(
                  nombre: gastoRecurso.nombreRecurso ?? 'Recurso ${gastoRecurso.idRecurso}',
                ),
                tarea: tareaModel.id ?? 0,
                fecha: fecha,
                cantidad: cantidad.toInt(),
              ));
            } catch (e) {
              print('Error parsing fecha in gastoRecurso: $e');
            }
          });
        }
      }
    }

    return Task(
      id: tareaModel.id ?? 0,
      isCompleted: tareaModel.completada,
      fieldName: tareaModel.parcelas?.isNotEmpty == true
          ? tareaModel.parcelas!.first.finca
          : null,
      variedad: tareaModel.parcelas?.isNotEmpty == true
          ? tareaModel.parcelas!.first.variedad
          : null,
      parcelaIds: tareaModel.parcelas?.map((p) => p.id).toList() ?? [],
      officer: tareaModel.responsable,
      type: tareaModel.tipoTarea,
      inicio: tareaModel.fechaInicio,
      fin: tareaModel.fechaFinal,
      empleados: horasEmpleados,
      vehiculos: vehiculos,
      recursos: recursos,
    );
  }

  /// Convierte un Task de la UI a un TareaModel para enviar al API
  static TareaModel toTareaModel(Task task, {int? parcelaId}) {
    // Convertir HorasEmpleado a GastoEmpleadoTarea
    Map<int, Map<String, double>> empleadosValues = {};
    for (var horasEmpleado in task.empleados) {
      // Necesitaríamos el ID real del empleado del API
      // Por ahora usamos un placeholder
      int empleadoId = horasEmpleado.id; // Esto habría que mejorarlo
      String fechaStr = horasEmpleado.fecha.toIso8601String().split('T')[0];
      
      if (!empleadosValues.containsKey(empleadoId)) {
        empleadosValues[empleadoId] = {};
      }
      empleadosValues[empleadoId]![fechaStr] = horasEmpleado.horas.toDouble();
    }

    List<GastoEmpleadoTarea> gastosEmpleados = empleadosValues.entries.map((entry) {
      return GastoEmpleadoTarea(
        idEmpleado: entry.key,
        valores: entry.value,
      );
    }).toList();

    // Convertir vehiculos a GastoVehiculoTarea
    List<GastoVehiculoTarea> gastosVehiculos = task.vehiculos.map((vehiculo) {
      return GastoVehiculoTarea(
        matricula: vehiculo.matricula ?? vehiculo.nombre, // Usar nombre si no hay matricula
      );
    }).toList();

    // Convertir recursos a GastoRecursoTarea
    Map<String, Map<String, double>> recursosValues = {};
    for (var recurso in task.recursos) {
      String recursoKey = recurso.recurso.nombre;
      String fechaStr = recurso.fecha.toIso8601String().split('T')[0];
      
      if (!recursosValues.containsKey(recursoKey)) {
        recursosValues[recursoKey] = {};
      }
      recursosValues[recursoKey]![fechaStr] = recurso.cantidad.toDouble();
    }

    // Aquí necesitaríamos mapear los nombres a IDs reales del API
    List<GastoRecursoTarea> gastosRecursos = [];

    // Crear lista de parcelas
    List<ParcelaTarea>? parcelas;
    if (parcelaId != null) {
      parcelas = [ParcelaTarea(id: parcelaId)];
    }

    return TareaModel(
      id: task.id != 0 ? task.id : null,
      tipoTarea: task.type ?? '',
      nombre: task.fieldName,
      fechaInicio: task.inicio,
      fechaFinal: task.fin,
      responsable: task.officer,
      completada: task.isCompleted,
      parcelas: parcelas,
      gastosEmpleados: gastosEmpleados.isNotEmpty ? gastosEmpleados : null,
      gastosVehiculos: gastosVehiculos.isNotEmpty ? gastosVehiculos : null,
      gastosRecursos: gastosRecursos.isNotEmpty ? gastosRecursos : null,
    );
  }

  /// Convierte una lista de TareaModel a List<Task>
  static List<Task> toTaskList(List<TareaModel> tareaModels) {
    return tareaModels.map((tm) => toTask(tm)).toList();
  }
}
