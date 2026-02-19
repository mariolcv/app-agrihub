import 'package:flutter/material.dart';

import 'calendar_screen.dart';
import 'utils.dart';
import 'data.dart';
import 'editTask_screen.dart';
import 'app_menu.dart';
import 'viewTask_screen.dart';
import 'repositories/task_repository.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({super.key, required this.title, DateTime? selectedDate})
      : initialSelectedDate = selectedDate ?? DateTime.now();

  final String title;
  final DateTime initialSelectedDate;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late DateTime selectedDate;
  final TaskRepository _taskRepository = TaskRepository();
  List<Task> _tasks = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialSelectedDate;
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tasks = await _taskRepository.getTasksForDay(selectedDate);
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar tareas: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    try {
      await _taskRepository.toggleTaskCompletion(task.id, !task.isCompleted);
      await _loadTasks(); // Recargar las tareas
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar tarea: $e')),
        );
      }
    }
  }

  void _editTask(Task task) async {
    // Navegar a la pantalla de edición
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditarTareaPage(task: task),
      ),
    ).then((_) => _loadTasks()); // Recargar al volver
  }

  void _viewTask(Task task) async {
    try {
      // Cargar los detalles completos de la tarea
      final taskDetails = await _taskRepository.getTaskById(task.id);
      if (!mounted) return;
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MostrarTareaPage(tarea: taskDetails),
        ),
      ).then((_) => _loadTasks()); // Recargar al volver
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar tarea: $e')),
      );
    }
  }

  Future<void> _deleteTask(Task task) async {
    try {
      // Mostrar diálogo de confirmación
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: const Text('¿Estás seguro de que deseas eliminar esta tarea?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Eliminar'),
              ),
            ],
          );
        },
      );

      if (confirmed == true) {
        // Eliminar tarea usando el repositorio
        await _taskRepository.deleteTask(task.id);
        
        // Actualizar la lista local
        setState(() {
          _tasks.removeWhere((t) => t.id == task.id);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tarea eliminada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar tarea: $e')),
        );
      }
    }
  }

  Widget _buildTaskItem(Task task) {
    String titulo = '${task.fieldName ?? "Sin parcela"}: ${task.type ?? "Sin tipo"}';
    String subtitulo = 'Responsable: ${task.officer ?? "Sin asignar"}';
    return Padding(
      key: ValueKey(task.id),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTap: () => _viewTask(task),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    subtitulo,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: task.isCompleted ? Colors.green : Colors.grey,
                  ),
                  onPressed: () => _toggleTaskCompletion(task),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editTask(task),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteTask(task),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: () => _viewTask(task),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Task> tareasProgramadas = _tasks.where((task) => !task.isCompleted).toList();
    List<Task> tareasCompletadas = _tasks.where((task) => task.isCompleted).toList();

    return Scaffold(
      drawer: buildAppDrawer(context),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CalendarScreen(),
                ),
              ).then((_) => _loadTasks()); // Recargar al volver
            },
          ),
        ],
      ),
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! < 0) {
            // Swiped left
            setState(() {
              selectedDate = selectedDate.add(const Duration(days: 1));
            });
            _loadTasks();
          } else if (details.primaryVelocity! > 0) {
            // Swiped right
            setState(() {
              selectedDate = selectedDate.subtract(const Duration(days: 1));
            });
            _loadTasks();
          }
        },
        child: Column(
          children: [
            Container(
              color: Colors.grey[200],
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      setState(() {
                        selectedDate = selectedDate.subtract(const Duration(days: 1));
                      });
                      _loadTasks();
                    },
                  ),
                  Text(
                    getStringDate(selectedDate),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () {
                      setState(() {
                        selectedDate = selectedDate.add(const Duration(days: 1));
                      });
                      _loadTasks();
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Text(
                          "Tareas programadas",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(),
                        if (tareasProgramadas.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'No hay tareas programadas',
                              style: TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          )
                        else
                          ...tareasProgramadas.map((task) => _buildTaskItem(task)),
                        const SizedBox(height: 16),
                        const Text(
                          "Tareas completadas",
                          style: TextStyle(
                fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(),
                        if (tareasCompletadas.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'No hay tareas completadas',
                              style: TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          )
                        else
                          ...tareasCompletadas.map((task) => _buildTaskItem(task)),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EditarTareaPage(),
            ),
          ).then((_) => _loadTasks()); // Recargar al volver
        },
        label: const Text("Nueva tarea"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.lightGreenAccent,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
