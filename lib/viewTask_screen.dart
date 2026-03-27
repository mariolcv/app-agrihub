import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'editTask_screen.dart';
import 'data.dart';
import 'repositories/task_repository.dart';

class MostrarTareaPage extends StatelessWidget {
  final Task tarea;
  final TaskRepository _taskRepository = TaskRepository();

  MostrarTareaPage({super.key, required this.tarea});

  Widget buildCampo(String titulo, String contenido) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.grey),
          ),
          child: Text(contenido),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget buildListaEmpleados(BuildContext context, List<HorasEmpleado> elementos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Empleados', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ..._groupEmpleados(elementos).entries.map((entry) {
          final empleado = entry.value.first.empleado;
          final total = entry.value.fold<int>(0, (s, r) => s + r.horas);
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 0.0),
            leading: CircleAvatar(child: Icon(empleado.foto.icon)),
            title: Text(empleado.nombre),
            subtitle: Text('Horas: $total'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.calendar_month_outlined),
                  onPressed: () {
                    // build date list for the task range
                    List<DateTime> dates = [];
                    DateTime cur = DateTime(tarea.inicio.year, tarea.inicio.month, tarea.inicio.day);
                    final last = DateTime(tarea.fin.year, tarea.fin.month, tarea.fin.day);
                    while (!cur.isAfter(last)) { dates.add(cur); cur = cur.add(const Duration(days: 1)); }

                    final Map<DateTime,int> dayMap = { for (var r in entry.value) DateTime(r.fecha.year, r.fecha.month, r.fecha.day): r.horas };

                    showDialog(context: context, builder: (BuildContext context) {
                      return AlertDialog(
                        title: Row(children: [const SizedBox(width: 8), Flexible(child: Text('Distribución de las horas de ${empleado.nombre}'))]),
                        content: SizedBox(
                          width: double.maxFinite,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(children: [Expanded(flex:1, child: Center(child: Text('Día', style: TextStyle(fontWeight: FontWeight.bold)))), Expanded(flex:1, child: Center(child: Text('Horas', style: TextStyle(fontWeight: FontWeight.bold))))]),
                              const SizedBox(height:8),
                              Flexible(child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: dates.map((d) { final label = DateFormat('d MMM').format(d); final hours = dayMap[d] ?? 0; return Padding(padding: const EdgeInsets.symmetric(vertical:4.0), child: Row(children: [Expanded(child: Center(child: Text(label))), Expanded(child: Center(child: Text(hours.toString())))])); }).toList(),),),),
                            ],
                          ),
                        ),
                        actions: [Center(child: TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')))],
                      );
                    });
                  },
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget buildListaVehiculos(List<Vehiculo> elementos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Vehiculos', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...elementos.map((elemento) {
          // Determinar el texto a mostrar: nombre o nombre con accesorio
          String displayText = elemento.nombre;
          if (elemento.accesorioNombre != null && elemento.accesorioNombre!.isNotEmpty) {
            displayText = '$displayText con ${elemento.accesorioNombre}';
          }
          
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 0.0),
            leading: CircleAvatar(
              child: Icon(elemento.foto.icon),
            ),
            title: Text(displayText),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget buildListaRecursos(BuildContext context, List<RegistroCantidadRecursos> elementos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recursos', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
  ..._groupRecursos(elementos).entries.map((entry) {
          final recurso = entry.value.first.recurso;
          final total = entry.value.fold<int>(0, (s, r) => s + r.cantidad);
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 0.0),
            leading: CircleAvatar(child: Icon(recurso.foto.icon)),
            title: Text(recurso.nombre),
            subtitle: Text('Cantidad: $total ${recurso.unidades}'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: const Icon(Icons.calendar_month_outlined), onPressed: () {
              List<DateTime> dates = [];
              DateTime cur = DateTime(tarea.inicio.year, tarea.inicio.month, tarea.inicio.day);
              final last = DateTime(tarea.fin.year, tarea.fin.month, tarea.fin.day);
              while (!cur.isAfter(last)) { dates.add(cur); cur = cur.add(const Duration(days: 1)); }
              final Map<DateTime,int> dayMap = { for (var r in entry.value) DateTime(r.fecha.year, r.fecha.month, r.fecha.day): r.cantidad };
              showDialog(context: context, builder: (BuildContext context) { return AlertDialog(title: Row(children: [const SizedBox(width: 8), Flexible(child: Text('Distribución de ${recurso.nombre} por días'))]), content: SizedBox(width: double.maxFinite, child: Column(mainAxisSize: MainAxisSize.min, children: [Row(children: [Expanded(flex:1, child: Center(child: Text('Día', style: TextStyle(fontWeight: FontWeight.bold)))), Expanded(flex:1, child: Center(child: Text(recurso.unidades, style: const TextStyle(fontWeight: FontWeight.bold))))]), const SizedBox(height:8), Flexible(child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: dates.map((d) { final label = DateFormat('d MMM').format(d); final qty = dayMap[d] ?? 0; return Padding(padding: const EdgeInsets.symmetric(vertical:4.0), child: Row(children: [Expanded(child: Center(child: Text(label))), Expanded(child: Center(child: Text(qty.toString())))])); }).toList(),),),),],),), actions: [Center(child: TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')))],); });
            })]),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  Map<String, List<HorasEmpleado>> _groupEmpleados(List<HorasEmpleado> list) {
    final Map<String, List<HorasEmpleado>> m = {};
    for (var r in list) {
      m.putIfAbsent(r.empleado.nombre, () => []).add(r);
    }
    return m;
  }

  Map<String, List<RegistroCantidadRecursos>> _groupRecursos(List<RegistroCantidadRecursos> list) {
    final Map<String, List<RegistroCantidadRecursos>> m = {};
    for (var r in list) {
      m.putIfAbsent(r.recurso.nombre, () => []).add(r);
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    final String estadoDeTareaString = tarea.isCompleted ? 'Completada' : 'Pendiente';
    final String fechas = tarea.inicio == tarea.fin
          ? DateFormat('dd/MM/yyyy').format(tarea.inicio)
          : '${DateFormat('dd/MM/yyyy').format(tarea.inicio)} - ${DateFormat('dd/MM/yyyy').format(tarea.fin)}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarea'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final updatedTask = await Navigator.push<Task>(
                context,
                MaterialPageRoute(
                  builder: (context) => EditarTareaPage(task: tarea),
                ),
              );

              if (!context.mounted || updatedTask == null) {
                return;
              }

              Task taskToShow = updatedTask;
              try {
                taskToShow = await _taskRepository.getTaskById(updatedTask.id);
              } catch (_) {
                // If refresh fails, still show the edited task returned by the form.
              }

              if (!context.mounted) {
                return;
              }

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => MostrarTareaPage(tarea: taskToShow),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tarea.type != null) buildCampo('Tipo de tarea', tarea.type!),
            if (tarea.fieldName != null) buildCampo('Parcela', tarea.fieldName!),
            if (tarea.variedad != null) buildCampo('Variedad', tarea.variedad!),
            buildCampo('Estado de la tarea', estadoDeTareaString),
            buildCampo('Fechas', fechas),
            if (tarea.officer != null) buildCampo('Responsable', tarea.officer!),
            if (tarea.empleados.isNotEmpty)
              buildListaEmpleados(context, tarea.empleados),
            if (tarea.vehiculos.isNotEmpty)
              buildListaVehiculos(tarea.vehiculos),
            if (tarea.recursos.isNotEmpty)
              buildListaRecursos(context, tarea.recursos),
          ],
        ),
      ),
    );
  }
}
