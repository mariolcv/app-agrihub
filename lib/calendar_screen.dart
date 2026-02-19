import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'utils.dart';
import 'viewTask_screen.dart';
import 'data.dart';
import 'repositories/task_repository.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final TaskRepository _taskRepository = TaskRepository();
  late final ValueNotifier<List<Task>> _selectedTasks;
  DateTime? _selectedDay;
  DateTime _focusedDay = DateTime.now();
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedTasks = ValueNotifier([]);
    _loadTasksForSelectedDay();
  }

  @override
  void dispose() {
    _selectedTasks.dispose();
    super.dispose();
  }

  Future<void> _loadTasksForSelectedDay() async {
    if (_selectedDay == null) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final tasks = await _taskRepository.getTasksForDay(_selectedDay!);
      _selectedTasks.value = tasks;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar tareas: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _seleccionarHoy() {
    setState(() {
      _focusedDay = DateTime.now();
      _selectedDay = _focusedDay;
    });
    _loadTasksForSelectedDay();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Calendario",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[300],
              ),
              padding: const EdgeInsets.all(8),
              child: Text(
                DateTime.now().day.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            onPressed: _seleccionarHoy,
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar<Task>(
            locale: 'es_ES',
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2034, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _loadTasksForSelectedDay();
            },
            calendarFormat: _calendarFormat,
            availableCalendarFormats: const {
              CalendarFormat.month: 'Mes',
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            startingDayOfWeek: StartingDayOfWeek.monday,

            // TODO: color of "sun" from sunday to red

            calendarBuilders: CalendarBuilders(
              // color of all sundays in red
              defaultBuilder: (context, day, focusedDay) {
                if (day.weekday == DateTime.sunday) {
                  return Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }
                return null;
              },
              // color of the selected day
              selectedBuilder: (context, date, events) => Container(
                margin: const EdgeInsets.all(4.0),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.lightGreen, // Color for selected day
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${date.day}',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              // set the color of the focused day
              todayBuilder: (context, date, events) => Container(
                margin: const EdgeInsets.all(4.0),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black),
                ),
                child: Text(
                  '${date.day}',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
          ),
          Container(
            alignment: Alignment.centerLeft,
            margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Text(
              tituloTareas(_selectedDay!),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Divider(
            color: Colors.black,
            thickness: 1,
            indent: 16,
            endIndent: 16,
          ),
          Expanded(
            child: ValueListenableBuilder<List<Task>>(
              valueListenable: _selectedTasks,
              builder: (context, value, _) {
                return ListView.builder(
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    final task = value[index];
                    return _buildResumenTarea(
                      _getTitleTask(task), // Función para obtener el título adecuado
                      _getIconForEvent(task), // Función para obtener el icono adecuado
                      _getColorForEvent(task), // Función para obtener el color adecuado
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => MostrarTareaPage(tarea: task)));
                      },
                    );
                  },
                );
              },
            ),
          ),
          
        ],
      ),
    );
  }

  Widget _buildResumenTarea(String titulo, IconData icono, Color color, {VoidCallback? onTap}) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            constraints: BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icono, color: color),
          ),
          title: Text(titulo),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: onTap,
        ),
        const Divider(
          color: Colors.black,
          thickness: 1,
          indent: 16,
          endIndent: 16,
        ),
      ],
      
    );
  }

  String _getTitleTask(Task task) {
    return '${task.fieldName}: ${task.officer}';
  }

  IconData _getIconForEvent(Task task) {
    return task.isCompleted ? Icons.check : Icons.access_time;
  }

  Color _getColorForEvent(Task task) {
    return task.isCompleted ? Colors.green : Colors.grey;
  }

}