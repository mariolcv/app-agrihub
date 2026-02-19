import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import 'data.dart';
import 'app_menu.dart';
import 'repositories/task_repository.dart';

// TODO: Actualizar esta pantalla para usar TaskRepository en lugar de data.tasks
// Cargar las tareas del mes actual cuando se inicia o cambia de mes
// Ejemplo: final tasks = await _taskRepository.getTasksForDateRange(startOfMonth, endOfMonth);

class MyWorkingHoursPage extends StatefulWidget {
  const MyWorkingHoursPage({super.key});

  @override
  State<MyWorkingHoursPage> createState() => _MyWorkingHoursPageState();
}

class _MyWorkingHoursPageState extends State<MyWorkingHoursPage> {
  final TaskRepository _taskRepository = TaskRepository();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _showMonthlyBreakdown = false;
  List<Task> _monthTasks = []; // Tareas del mes actual
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadMonthTasks(_focusedDay);
  }

  /// Carga las tareas del mes desde el backend
  Future<void> _loadMonthTasks(DateTime month) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Obtener el primer y último día del mes
      final firstDay = DateTime(month.year, month.month, 1);
      final lastDay = DateTime(month.year, month.month + 1, 0);
      
      print('📅 Cargando tareas del mes ${DateFormat('MM/yyyy').format(month)}');
      
      // ⚠️ TEMPORAL: Usa lista básica sin gastos hasta que exista endpoint
      //    GET /api/empleados/[id]/horas-trabajadas?fecha_desde=X&fecha_hasta=Y
      // TODO: Cuando exista el endpoint, reemplazar por:
      //    final horasData = await _empleadoRepository.getHorasTrabajadas(empleadoId, firstDay, lastDay);
      final tasks = await _taskRepository.getTasksForDateRange(firstDay, lastDay);
      
      setState(() {
        _monthTasks = tasks;
        _isLoading = false;
      });
      
      print('✅ Tareas cargadas: ${tasks.length}');
      print('⚠️ Nota: Estas tareas NO tienen gastos_empleados (datos básicos solamente)');
      print('   Las horas trabajadas mostrarán 0 hasta que exista el endpoint de horas');
    } catch (e) {
      print('❌ Error al cargar tareas del mes: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  int _hoursForDay(DateTime day) {
    if (currentUser == null) return 0;
    
    final key = DateTime(day.year, day.month, day.day);
    int total = 0;
    
    for (var t in _monthTasks) {
      for (var he in t.empleados) {
        if (he.empleado.usuario?.nombre_usuario == currentUser!.nombre_usuario) {
          final d = DateTime(he.fecha.year, he.fecha.month, he.fecha.day);
          if (d == key) total += he.horas;
        }
      }
    }
    
    return total;
  }

  Map<String, int> _hoursPerTaskForDay(DateTime day) {
    final Map<String, int> m = {};
    if (currentUser == null) return m;
    final key = DateTime(day.year, day.month, day.day);
    for (var t in _monthTasks) {
      int sum = 0;
      for (var he in t.empleados) {
        if (he.empleado.usuario?.nombre_usuario == currentUser!.nombre_usuario) {
          final d = DateTime(he.fecha.year, he.fecha.month, he.fecha.day);
          if (d == key) sum += he.horas;
        }
      }
      // prefer task.type (tipo) over fieldName for the label
      if (sum > 0) m[t.type ?? t.fieldName ?? 'Tarea ${t.id}'] = sum;
    }
    return m;
  }

  int _hoursForMonth(DateTime month) {
    if (currentUser == null) return 0;
    int total = 0;
    for (var t in _monthTasks) {
      for (var he in t.empleados) {
        if (he.empleado.usuario?.nombre_usuario == currentUser!.nombre_usuario) {
          if (he.fecha.year == month.year && he.fecha.month == month.month) total += he.horas;
        }
      }
    }
    return total;
  }

  // Build grouped breakdown: Map<DateTime, List<MapEntry(taskName,hours)>>
  Map<DateTime, List<MapEntry<String,int>>> _monthlyBreakdown(DateTime month) {
    final Map<DateTime, List<MapEntry<String,int>>> m = {};
    if (currentUser == null) return m;
    for (var t in _monthTasks) {
      for (var he in t.empleados) {
        if (he.empleado.usuario?.nombre_usuario == currentUser!.nombre_usuario) {
          if (he.fecha.year == month.year && he.fecha.month == month.month) {
            final d = DateTime(he.fecha.year, he.fecha.month, he.fecha.day);
            final name = t.type ?? 'Tarea ${t.id}';
            m.putIfAbsent(d, () => []).add(MapEntry(name, he.horas));
          }
        }
      }
    }
    // Ensure deterministic ordering by date ascending
    final sorted = Map.fromEntries(m.entries.toList()..sort((a,b) => a.key.compareTo(b.key)));
    return sorted;
  }

  Color _colorForDay(DateTime day) {
    final int hours = _hoursForDay(day);
    if (hours == 0) return Colors.grey;
    if (hours < 8) return Colors.yellow;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
  final monthLabelRaw = DateFormat('MMMM', 'es').format(_focusedDay);
  final monthLabel = monthLabelRaw.isNotEmpty ? monthLabelRaw[0].toUpperCase() + monthLabelRaw.substring(1) : monthLabelRaw;
    final monthTotal = _hoursForMonth(_focusedDay);
    final selected = _selectedDay ?? _focusedDay;
    final dayDetail = _hoursPerTaskForDay(selected);
    final breakdown = _monthlyBreakdown(_focusedDay);

    return Scaffold(
      drawer: buildAppDrawer(context),
      appBar: AppBar(
        title: const Text('Mis horas'),
        leading: Builder(builder: (context) => IconButton(icon: const Icon(Icons.menu, color: Colors.black), onPressed: () => Scaffold.of(context).openDrawer())),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Cargando horas trabajadas...'),
                  ],
                ),
              )
            : SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header summary (month label centered)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text('Total en $monthLabel: $monthTotal h', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 12),

                // Calendar
                TableCalendar(
                  locale: 'es_ES',
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2035, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: CalendarFormat.month,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Mes',
                  },
                    headerStyle: const HeaderStyle(
                      titleCentered: true,
                      formatButtonVisible: false,
                    ),
                  selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    setState(() {
                      _focusedDay = focusedDay;
                    });
                    // Cargar tareas del nuevo mes
                    _loadMonthTasks(focusedDay);
                  },
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                      final color = _colorForDay(day);
                      final textColor = day.weekday == DateTime.sunday ? Colors.red : null;
                      // If no hours (grey), don't draw the grey circle; show only the number
                      if (color == Colors.grey) {
                        return Center(child: Text('${day.day}', style: TextStyle(color: textColor)));
                      }
                      return Center(
                        child: Container(
                          margin: const EdgeInsets.all(6.0),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                          child: Center(child: Text('${day.day}', style: TextStyle(color: textColor))),
                        ),
                      );
                    },
                    todayBuilder: (context, day, focusedDay) {
                      final color = _colorForDay(day);
                      final textColor = day.weekday == DateTime.sunday ? Colors.red : Colors.black;
                      // If no hours (grey), show only the number (no grey circle)
                      if (color == Colors.grey) {
                        return Center(child: Text('${day.day}', style: TextStyle(color: textColor)));
                      }
                      return Center(
                        child: Container(
                          margin: const EdgeInsets.all(4.0),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black),
                          ),
                          child: Center(child: Text('${day.day}', style: TextStyle(color: textColor))),
                        ),
                      );
                    },
                    selectedBuilder: (context, day, focusedDay) {
                      final color = _colorForDay(day);
                      final textColor = day.weekday == DateTime.sunday ? Colors.red : Colors.black;
                      if (color == Colors.grey) {
                        return Center(child: Text('${day.day}', style: TextStyle(color: textColor)));
                      }
                      return Center(
                        child: Container(
                          margin: const EdgeInsets.all(4.0),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black),
                          ),
                          child: Center(child: Text('${day.day}', style: TextStyle(color: textColor))),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),
                // Detail for selected day
                Text('Detalle completo del día ${DateFormat('d MMMM yyyy', 'es').format(selected)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (dayDetail.isEmpty)
                  const Text('No hay registros para este día.'),
                if (dayDetail.isNotEmpty)
                  Column(
                    children: dayDetail.entries.map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(e.key),
                          SizedBox(width: 12),
                          Text('${e.value} h'),
                        ],
                      ),
                    )).toList(),
                  ),

                const SizedBox(height: 12),
                // Toggle breakdown (centered with extra top margin)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.lightGreenAccent, foregroundColor: Colors.black),
                      onPressed: () => setState(() => _showMonthlyBreakdown = !_showMonthlyBreakdown),
                      child: Text(_showMonthlyBreakdown ? 'Ocultar desglose' : 'Desglose del mes por días'),
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                if (_showMonthlyBreakdown)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          // header row
                          Row(
                            children: const [
                              Expanded(flex: 2, child: Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold))),
                              Expanded(flex: 4, child: Text('Tarea', style: TextStyle(fontWeight: FontWeight.bold))),
                              Expanded(flex: 2, child: Text('Horas', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                          ),
                          const Divider(),
                          // rows grouped by week within the month, with a weekly total row
                          ...(() {
                            final List<Widget> weekWidgets = [];
                            // compute first and last day of the month
                            final first = DateTime(_focusedDay.year, _focusedDay.month, 1);
                            final last = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

                            // build weeks: each week is a list of DateTimes within the month
                            List<DateTime> currentWeekDates = [];
                            DateTime cursor = first;
                            while (!cursor.isAfter(last)) {
                              currentWeekDates.add(cursor);
                              // end week on Sunday (weekday == 7) or at month end
                              if (cursor.weekday == DateTime.sunday || cursor.isAtSameMomentAs(last)) {
                                // process this week
                                // collect weekly total
                                int weekTotal = 0;
                                for (var d in currentWeekDates) {
                                  final key = DateTime(d.year, d.month, d.day);
                                  final entries = breakdown[key];
                                  if (entries != null) {
                                    for (var e in entries) {
                                      weekTotal += e.value;
                                    }
                                  }
                                }

                                // week header with total
                                final weekStart = currentWeekDates.first;
                                final weekEnd = currentWeekDates.last;
                                final headerLabel = 'Total de horas semana ${DateFormat('d/MM', 'es').format(weekStart)} al ${DateFormat('d/MM', 'es').format(weekEnd)}: $weekTotal h';
                                weekWidgets.add(Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                                  child: Row(
                                    children: [
                                      Expanded(child: Text(headerLabel, style: const TextStyle(fontWeight: FontWeight.bold))),
                                    ],
                                  ),
                                ));

                                // list tasks grouped by date for this week
                                for (var d in currentWeekDates) {
                                  final key = DateTime(d.year, d.month, d.day);
                                  final entries = breakdown[key];
                                  if (entries == null) continue;
                                  final dateLabel = DateFormat('d MMM', 'es').format(key);
                                  for (var i = 0; i < entries.length; i++) {
                                    final item = entries[i];
                                    weekWidgets.add(Row(
                                      children: [
                                        Expanded(flex: 2, child: i == 0 ? Text(dateLabel) : const SizedBox()),
                                        Expanded(flex: 4, child: Text(item.key)),
                                        Expanded(flex: 2, child: Text('${item.value} h')),
                                      ],
                                    ));
                                  }
                                }

                                // separator after week
                                weekWidgets.add(const Divider());

                                currentWeekDates = [];
                              }
                              cursor = cursor.add(const Duration(days: 1));
                            }

                            return weekWidgets;
                          })(),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
