import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import 'app_menu.dart';
import 'data.dart';
import 'repositories/empleado_repository.dart';
import 'models/empleado_model.dart';

class EditWorkingHoursPage extends StatefulWidget {
  final DateTime? initialDate;
  const EditWorkingHoursPage({super.key, this.initialDate});

  @override
  State<EditWorkingHoursPage> createState() => _EditWorkingHoursPageState();
}

class _EditWorkingHoursPageState extends State<EditWorkingHoursPage> {
  late DateTime _selectedDate;
  final EmpleadoRepository _empleadoRepository = EmpleadoRepository();
  List<EmpleadoModel> _empleadosFromAPI = [];
  bool _isLoadingEmpleados = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _loadEmpleados();
  }
  
  Future<void> _loadEmpleados() async {
    try {
      final empleados = await _empleadoRepository.getEmpleados();
      setState(() {
        _empleadosFromAPI = empleados;
        _isLoadingEmpleados = false;
      });
      _loadEmployeesForDate();
    } catch (e) {
      setState(() {
        _isLoadingEmpleados = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar empleados: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      _loadEmployeesForDate();
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _loadEmployeesForDate() {
    final Map<String, Empleado> allEmps = {};
    
    // Cargar empleados desde API si están disponibles
    for (var e in _empleadosFromAPI) {
      allEmps[e.nombre] = Empleado(
        nombre: e.nombre,
        foto: const Icon(Icons.person),
        contrato: 'fijo', // El modelo de API no tiene esta info, usar default
      );
    }
    
    // include any employees found in tasks
    for (var t in data.tasks) {
      for (var he in t.empleados) {
        if (!allEmps.containsKey(he.empleado.nombre)) {
          allEmps[he.empleado.nombre] = he.empleado;
        }
      }
    }

    final List<_EmployeeRow> fixed = [];
    final List<_EmployeeRow> temp = [];

    for (var emp in allEmps.values) {
      int total = 0;
      DateTime? minInicio;
      DateTime? maxFin;
      for (var t in data.tasks) {
        for (var he in t.empleados) {
          if (he.empleado.nombre == emp.nombre && _isSameDay(he.fecha, _selectedDate)) {
            total += he.horas;
            if (minInicio == null || he.inicio.isBefore(minInicio)) minInicio = he.inicio;
            if (maxFin == null || he.fin.isAfter(maxFin)) maxFin = he.fin;
          }
        }
      }

      TimeOfDay? entrada = minInicio != null ? TimeOfDay(hour: minInicio.hour, minute: minInicio.minute) : null;
      TimeOfDay? salida = maxFin != null ? TimeOfDay(hour: maxFin.hour, minute: maxFin.minute) : null;

      final row = _EmployeeRow(empleado: emp, asistencia: total > 0, entrada: entrada, salida: salida, totalHoras: total);
      if (emp.contrato == 'fijo') {
        fixed.add(row);
      } else {
        temp.add(row);
      }
    }

    // sort: those with hours first, then by name
    int sorter(_EmployeeRow a, _EmployeeRow b) {
      if (a.totalHoras > 0 && b.totalHoras == 0) return -1;
      if (a.totalHoras == 0 && b.totalHoras > 0) return 1;
      return a.empleado.nombre.compareTo(b.empleado.nombre);
    }

    fixed.sort(sorter);
    temp.sort(sorter);

    setState(() {
      _fixedEmployees = fixed;
      _tempEmployees = temp;
    });
  }
  String _horarioOption = 'Todo el personal';
  final List<String> _horarioOptions = ['Todo el personal', 'Personal con registro de llegada', 'Personal temporal', 'Personal fijo'];
  TimeOfDay? _horaEntrada;
  TimeOfDay? _horaSalida;
  // Local editable representation of employees for the selected date
  List<_EmployeeRow> _fixedEmployees = [];
  List<_EmployeeRow> _tempEmployees = [];

  // location label helper removed (not used in this screen)

  void _openCalendarModal() async {
    DateTime tempSelected = _selectedDate;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setStateDialog) => AlertDialog(
          title: const Text('Seleccionar fecha'),
          content: SizedBox(
            width: double.maxFinite,
            height: 360,
            child: TableCalendar(
              locale: 'es_ES',
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2035, 12, 31),
              focusedDay: tempSelected,
              startingDayOfWeek: StartingDayOfWeek.monday,
              headerStyle: const HeaderStyle(titleCentered: true, formatButtonVisible: false),
              selectedDayPredicate: (d) => isSameDay(d, tempSelected),
              onDaySelected: (selectedDay, focusedDay) {
                setStateDialog(() => tempSelected = selectedDay);
              },
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  final textColor = day.weekday == DateTime.sunday ? Colors.red : null;
                  return Center(child: Text('${day.day}', style: TextStyle(color: textColor)));
                },
                todayBuilder: (context, day, focusedDay) {
                  final textColor = day.weekday == DateTime.sunday ? Colors.red : Colors.black;
                  return Center(child: Container(margin: const EdgeInsets.all(4.0), width: 36, height: 36, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.black)), child: Center(child: Text('${day.day}', style: TextStyle(color: textColor)))));
                },
                selectedBuilder: (context, day, focusedDay) {
                  final textColor = day.weekday == DateTime.sunday ? Colors.red : Colors.white;
                  return Center(child: Container(margin: const EdgeInsets.all(4.0), width: 36, height: 36, decoration: BoxDecoration(color: Colors.lightGreen, shape: BoxShape.circle), child: Center(child: Text('${day.day}', style: TextStyle(color: textColor)))));
                },
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                // replace current page with editor for selected day
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => EditWorkingHoursPage(initialDate: tempSelected)));
              },
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  Future<TimeOfDay?> _pickTime(TimeOfDay initial) async {
    return showTimePicker(context: context, initialTime: initial, initialEntryMode: TimePickerEntryMode.input);
  }

  @override
  Widget build(BuildContext context) {
  final dateLabel = DateFormat('dd MMM yyyy', 'es').format(_selectedDate);
    return Scaffold(
      drawer: buildAppDrawer(context),
      appBar: AppBar(
        leading: Builder(builder: (context) => IconButton(icon: const Icon(Icons.menu, color: Colors.black), onPressed: () => Scaffold.of(context).openDrawer())),
        title: Text('Distribución jornadas'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.black),
            onPressed: _openCalendarModal,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Large centered date with subtle grey background
                Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 0),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                  dateLabel,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                ),
              const SizedBox(height: 16),
              // Horario común: centered label and dropdown below
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Center(child: Text('Establecer horario común para', style: const TextStyle(fontWeight: FontWeight.bold))),
                      const SizedBox(height: 8),
                      Center(
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 56, maxWidth: 360),
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: DropdownButton<String>(
                          value: _horarioOption,
                          isExpanded: true,
                          items: _horarioOptions.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                          selectedItemBuilder: (context) => _horarioOptions.map((o) => Container(
                            height: 56,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: Text(o, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                          )).toList(),
                          onChanged: (v) => setState(() { if (v != null) _horarioOption = v; }),
                          ),
                        ),
                      ),
                      // Entrada / Salida time pickers (larger) + aplicar button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                          child: GestureDetector(
                            onTap: () async {
                            final picked = await _pickTime(_horaEntrada ?? const TimeOfDay(hour: 9, minute: 0));
                            if (picked != null) setState(() => _horaEntrada = picked);
                            },
                            child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                            child: Center(
                              child: _horaEntrada == null
                                ? Text('entrada', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 18))
                                : Text(_horaEntrada!.format(context), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            ),
                            ),
                          ),
                          ),
                          const SizedBox(width: 8),
                          const Text('-', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Expanded(
                          child: GestureDetector(
                            onTap: () async {
                            final picked = await _pickTime(_horaSalida ?? const TimeOfDay(hour: 17, minute: 0));
                            if (picked != null) setState(() => _horaSalida = picked);
                            },
                            child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                            child: Center(
                              child: _horaSalida == null
                                ? Text('salida', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 18))
                                : Text(_horaSalida!.format(context), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            ),
                            ),
                          ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.lightGreen,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4), // Menos redondeado
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            setState(() {
                            // Aplica el horario común según la opción seleccionada
                            List<_EmployeeRow> target;
                            switch (_horarioOption) {
                              case 'Personal fijo':
                              target = _fixedEmployees;
                              break;
                              case 'Personal temporal':
                              target = _tempEmployees;
                              break;
                              case 'Personal con registro de llegada':
                              target = [..._fixedEmployees, ..._tempEmployees].where((e) => e.asistencia).toList();
                              break;
                              default:
                              target = [..._fixedEmployees, ..._tempEmployees];
                            }
                            for (var r in target) {
                              r.entrada = _horaEntrada;
                              r.salida = _horaSalida;
                              r.totalHoras = _computeHours(r.entrada, r.salida);
                            }
                            // reload to re-sort by registered hours and group by contrato
                            _loadEmployeesForDate();
                            });
                          },
                          child: const Text('Aplicar', style: TextStyle(color: Colors.black)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
              const SizedBox(height: 24),
              // Employee lists split by role
              _buildEmployeeSection('Personal fijo', _fixedEmployees),
              const SizedBox(height: 12),
              _buildEmployeeSection('Personal temporal', _tempEmployees),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeSection(String title, List<_EmployeeRow> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Column(
            children: [
              // header
              // Table layout: Nombre expands, other columns use intrinsic width; centers values
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(1),
                    1: IntrinsicColumnWidth(),
                    2: IntrinsicColumnWidth(),
                    3: IntrinsicColumnWidth(),
                    4: IntrinsicColumnWidth(),
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  border: TableBorder(horizontalInside: BorderSide(color: Color(0xFFECECEC), width: 1)),
                  children: [
                    // header
                    TableRow(children: [
                      Padding(padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0), child: Text('Nombre', style: const TextStyle(fontWeight: FontWeight.bold))),
                      Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0), child: Text('S/N', style: const TextStyle(fontWeight: FontWeight.bold)))),
                      Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0), child: Text('Entrada', style: const TextStyle(fontWeight: FontWeight.bold)))),
                      Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0), child: Text('Salida', style: const TextStyle(fontWeight: FontWeight.bold)))),
                      Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0), child: Text('Horas', style: const TextStyle(fontWeight: FontWeight.bold)))),
                    ]),
                    // data rows
                    ...rows.map((r) {
                      return TableRow(children: [
                        Padding(padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0), child: Text(r.empleado.nombre)),
                        Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: Switch(value: r.asistencia, onChanged: (v) => setState(() => r.asistencia = v)))),
                        Center(
                          child: GestureDetector(
                            onTap: () async {
                              final picked = await _pickTime(r.entrada ?? const TimeOfDay(hour: 9, minute: 0));
                              if (picked != null) {
                                setState(() {
                                r.entrada = picked;
                                // recompute totalHoras for display when user edits times
                                r.totalHoras = _computeHours(r.entrada, r.salida);
                              });
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                              child: r.entrada == null ? Text('Entrada', style: TextStyle(color: Colors.grey[600])) : Text(r.entrada!.format(context)),
                            ),
                          ),
                        ),
                        Center(
                          child: GestureDetector(
                            onTap: () async {
                              final picked = await _pickTime(r.salida ?? const TimeOfDay(hour: 17, minute: 0));
                              if (picked != null) {
                                setState(() {
                                r.salida = picked;
                                r.totalHoras = _computeHours(r.entrada, r.salida);
                              });
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                              child: r.salida == null ? Text('Salida', style: TextStyle(color: Colors.grey[600])) : Text(r.salida!.format(context)),
                            ),
                          ),
                        ),
                        Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: Text(r.totalHoras.toString()))),
                      ]);
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  int _computeHours(TimeOfDay? entrada, TimeOfDay? salida) {
    if (entrada == null || salida == null) return 0;
    final e = Duration(hours: entrada.hour, minutes: entrada.minute);
    final s = Duration(hours: salida.hour, minutes: salida.minute);
    final diff = s - e;
    final hrs = diff.inMinutes ~/ 60;
    return hrs < 0 ? 0 : hrs;
  }
}

class _EmployeeRow {
  Empleado empleado;
  bool asistencia;
  TimeOfDay? entrada;
  TimeOfDay? salida;
  int totalHoras;

  _EmployeeRow({required this.empleado, this.asistencia = true, this.entrada, this.salida, this.totalHoras = 0});
}
