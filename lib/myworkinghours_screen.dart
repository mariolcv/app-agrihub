import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import 'data.dart';
import 'app_menu.dart';
import 'repositories/task_repository.dart';
import 'utils.dart';
import 'services/auth_service.dart';
import 'services/app_logger.dart';

void print(Object? message) => AppLogger.i(message);

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
  final AuthService _authService = AuthService();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _showMonthlyBreakdown = false;
  List<Task> _monthTasks = []; // Tareas del mes actual
  Set<String> _currentUserAliases = <String>{};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _initScreen();
  }

  Future<void> _initScreen() async {
    await _loadCurrentUserAliases();
    await _loadMonthTasks(_focusedDay);
  }

  String _normalizeName(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u');
  }

  Future<void> _loadCurrentUserAliases() async {
    final aliases = <String>{};

    if (currentUser != null) {
      aliases.add(_normalizeName(currentUser!.nombre_usuario));
    }

    try {
      final user = await _authService.getCurrentUser();

      if (user.username.isNotEmpty) {
        aliases.add(_normalizeName(user.username));
      }
      if (user.empleado?.nombre.isNotEmpty == true) {
        aliases.add(_normalizeName(user.empleado!.nombre));
      }
    } catch (_) {
      // Continuar con aliases locales si falla /me
    }

    setState(() {
      _currentUserAliases = aliases;
    });
  }

  bool _isHoursRecordForCurrentUser(HorasEmpleado record) {
    if (_currentUserAliases.isEmpty) return false;

    final empleadoNombre = _normalizeName(record.empleado.nombre);
    if (_currentUserAliases.contains(empleadoNombre)) return true;

    final username = record.empleado.usuario?.nombre_usuario;
    if (username != null && username.trim().isNotEmpty) {
      if (_currentUserAliases.contains(_normalizeName(username))) return true;
    }

    return false;
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
      
      final tasks = await _taskRepository.getTasksForDateRangeWithDetails(firstDay, lastDay);
      
      setState(() {
        _monthTasks = tasks;
        _isLoading = false;
      });
      
      print('✅ Tareas cargadas: ${tasks.length}');
      final totalRegistrosHoras = tasks.fold<int>(0, (sum, t) => sum + t.empleados.length);
      print('✅ Registros de horas cargados: $totalRegistrosHoras');
    } catch (e) {
      print('❌ Error al cargar tareas del mes: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando horas trabajadas: $e')),
        );
      }
    }
  }

  int _hoursForDay(DateTime day) {
    if (_currentUserAliases.isEmpty) return 0;
    
    final key = DateTime(day.year, day.month, day.day);
    int total = 0;
    
    for (var t in _monthTasks) {
      for (var he in t.empleados) {
        if (_isHoursRecordForCurrentUser(he)) {
          final d = DateTime(he.fecha.year, he.fecha.month, he.fecha.day);
          if (d == key) total += he.horas;
        }
      }
    }
    
    return total;
  }

  Map<String, int> _hoursPerTaskForDay(DateTime day) {
    final Map<String, int> m = {};
    if (_currentUserAliases.isEmpty) return m;
    final key = DateTime(day.year, day.month, day.day);
    for (var t in _monthTasks) {
      int sum = 0;
      for (var he in t.empleados) {
        if (_isHoursRecordForCurrentUser(he)) {
          final d = DateTime(he.fecha.year, he.fecha.month, he.fecha.day);
          if (d == key) sum += he.horas;
        }
      }
      if (sum > 0) m[getTaskListTitle(t)] = sum;
    }
    return m;
  }

  int _hoursForMonth(DateTime month) {
    if (_currentUserAliases.isEmpty) return 0;
    int total = 0;
    for (var t in _monthTasks) {
      for (var he in t.empleados) {
        if (_isHoursRecordForCurrentUser(he)) {
          if (he.fecha.year == month.year && he.fecha.month == month.month) total += he.horas;
        }
      }
    }
    return total;
  }

  // Build grouped breakdown: Map<DateTime, List<MapEntry(taskName,hours)>>
  Map<DateTime, List<MapEntry<String,int>>> _monthlyBreakdown(DateTime month) {
    final Map<DateTime, List<MapEntry<String,int>>> m = {};
    if (_currentUserAliases.isEmpty) return m;
    for (var t in _monthTasks) {
      for (var he in t.empleados) {
        if (_isHoursRecordForCurrentUser(he)) {
          if (he.fecha.year == month.year && he.fecha.month == month.month) {
            final d = DateTime(he.fecha.year, he.fecha.month, he.fecha.day);
            final name = getTaskListTitle(t);
            m.putIfAbsent(d, () => []).add(MapEntry(name, he.horas));
          }
        }
      }
    }
    // Ensure deterministic ordering by date ascending
    final sorted = Map.fromEntries(m.entries.toList()..sort((a,b) => a.key.compareTo(b.key)));
    return sorted;
  }

  int _maxHoursForMonth(DateTime month) {
    if (_currentUserAliases.isEmpty) return 0;

    final Map<DateTime, int> byDay = {};
    for (var t in _monthTasks) {
      for (var he in t.empleados) {
        if (_isHoursRecordForCurrentUser(he) &&
            he.fecha.year == month.year &&
            he.fecha.month == month.month) {
          final key = DateTime(he.fecha.year, he.fecha.month, he.fecha.day);
          byDay[key] = (byDay[key] ?? 0) + he.horas;
        }
      }
    }

    if (byDay.isEmpty) return 0;
    return byDay.values.reduce((a, b) => a > b ? a : b);
  }

  Color? _heatmapColorForDay(DateTime day, int maxHoursInMonth) {
    final int hours = _hoursForDay(day);
    if (hours <= 0) return null;

    if (maxHoursInMonth <= 0) {
      return Colors.yellow.shade600;
    }

    final ratio = (hours / maxHoursInMonth).clamp(0.0, 1.0);
    return Color.lerp(Colors.yellow.shade600, Colors.green.shade600, ratio);
  }

  Color _dayTextColor(Color fillColor, {required bool isSunday}) {
    if (isSunday) return Colors.red;
    return fillColor.computeLuminance() < 0.5 ? Colors.white : Colors.black;
  }

  Widget _buildHeatmapLegend(int maxHoursInMonth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Leyenda (mapa de calor)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        const Text('Sin color = 0 h', style: TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 6),
        Container(
          height: 10,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              colors: [Colors.yellow.shade600, Colors.green.shade600],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('> 0 h', style: TextStyle(fontSize: 12)),
            Text('Máximo: $maxHoursInMonth h', style: const TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
  final monthLabelRaw = DateFormat('MMMM', 'es').format(_focusedDay);
  final monthLabel = monthLabelRaw.isNotEmpty ? monthLabelRaw[0].toUpperCase() + monthLabelRaw.substring(1) : monthLabelRaw;
    final monthTotal = _hoursForMonth(_focusedDay);
    final maxHoursInMonth = _maxHoursForMonth(_focusedDay);
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
                const SizedBox(height: 8),
                _buildHeatmapLegend(maxHoursInMonth),
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
                      final fillColor = _heatmapColorForDay(day, maxHoursInMonth);
                      if (fillColor == null) {
                        final textColor = day.weekday == DateTime.sunday ? Colors.red : null;
                        return Center(child: Text('${day.day}', style: TextStyle(color: textColor)));
                      }

                      final textColor = _dayTextColor(fillColor, isSunday: day.weekday == DateTime.sunday);
                      return Center(
                        child: Container(
                          margin: const EdgeInsets.all(6.0),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: fillColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(child: Text('${day.day}', style: TextStyle(color: textColor))),
                        ),
                      );
                    },
                    todayBuilder: (context, day, focusedDay) {
                      final fillColor = _heatmapColorForDay(day, maxHoursInMonth);
                      if (fillColor == null) {
                        final textColor = day.weekday == DateTime.sunday ? Colors.red : Colors.black;
                        return Center(child: Text('${day.day}', style: TextStyle(color: textColor)));
                      }

                      final textColor = _dayTextColor(fillColor, isSunday: day.weekday == DateTime.sunday);
                      return Center(
                        child: Container(
                          margin: const EdgeInsets.all(4.0),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: fillColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black),
                          ),
                          child: Center(child: Text('${day.day}', style: TextStyle(color: textColor))),
                        ),
                      );
                    },
                    selectedBuilder: (context, day, focusedDay) {
                      final fillColor = _heatmapColorForDay(day, maxHoursInMonth);
                      if (fillColor == null) {
                        final textColor = day.weekday == DateTime.sunday ? Colors.red : Colors.black;
                        return Center(child: Text('${day.day}', style: TextStyle(color: textColor)));
                      }

                      final textColor = _dayTextColor(fillColor, isSunday: day.weekday == DateTime.sunday);
                      return Center(
                        child: Container(
                          margin: const EdgeInsets.all(4.0),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: fillColor,
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
