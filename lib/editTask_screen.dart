import 'package:flutter/material.dart';
import 'package:gest_parcelas/data.dart';
import 'package:intl/intl.dart';
import 'repositories/empleado_repository.dart';
import 'repositories/vehiculo_repository.dart';
import 'repositories/recurso_repository.dart';
import 'repositories/accesorio_repository.dart';
import 'repositories/parcela_repository.dart';
import 'repositories/task_repository.dart';
import 'services/tarea_service.dart';
import 'models/parcela_model.dart';
import 'models/vehiculo_model.dart';

class EditarTareaPage extends StatefulWidget {
  final Task? task;

  const EditarTareaPage({super.key, this.task});

  @override
  _EditarTareaPageState createState() => _EditarTareaPageState();
}

class _EditarTareaPageState extends State<EditarTareaPage> {

  late Task _task;
  String? _estadoDeTarea;
  String _fechas = 'Selecciona una fecha';
  
  // Repositorios
  final EmpleadoRepository _empleadoRepository = EmpleadoRepository();
  final VehiculoRepository _vehiculoRepository = VehiculoRepository();
  final RecursoRepository _recursoRepository = RecursoRepository();
  final AccesorioRepository _accesorioRepository = AccesorioRepository(); // Para accesorios de vehículos
  final ParcelaRepository _parcelaRepository = ParcelaRepository();
  final TaskRepository _taskRepository = TaskRepository();
  
  // Datos cargados desde API
  List<String> nombreEmpleados = [];
  List<String> possiblesVehiculos = [];
  List<String> possiblesRecursos = [];
  List<String> possibleFields = [];
  List<String> possibleVariedades = [];
  List<String> possibleOfficers = [];
  List<String> possibleTypes = [];
  Map<String, VehiculoModel> _vehiculosByNombre = {};
  Map<String, VehiculoModel> _vehiculosByMatricula = {};
  
  List<ParcelaModel> _selectedParcelas = []; // Parcelas individuales seleccionadas
  
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _initializeTask();
    _loadData();
  }
  
  void _initializeTask() {
    if (widget.task != null) {
      // Modo edición: cargar datos completos desde el backend
      _loadFullTaskData();
    } else {
      // Modo creación: inicializar tarea vacía
      final DateTime now = DateTime.now();
      _task = Task(
        id: data.tasks.length,
        inicio: now,
        fin: now,
        isCompleted: false,
        nombre: null,
        fieldName: null,
        variedad: null,
        paraje: null,
        anoPlantacion: null,
        parcelaIds: [], // Lista vacía de parcelas
        officer: null,
        type: null,
        // now using flat record lists
        empleados: <HorasEmpleado>[],
        vehiculos: <Vehiculo>[],
        recursos: <RegistroCantidadRecursos>[],
      );
      _estadoDeTarea = 'Pendiente';
      _fechas = '${DateFormat('dd/MM/yyyy').format(now)} - ${DateFormat('dd/MM/yyyy').format(now)}';
    }
  }
  
  /// Carga los datos completos de la tarea desde el backend
  Future<void> _loadFullTaskData() async {
    try {
      // Primero inicializar con los datos básicos para evitar null
      setState(() {
        _task = widget.task!;
        _estadoDeTarea = _task.isCompleted ? 'Completada' : 'Pendiente';
        _fechas = '${DateFormat('dd/MM/yyyy').format(_task.inicio)} - ${DateFormat('dd/MM/yyyy').format(_task.fin)}';
      });
      
      print('📥 Cargando datos completos de la tarea ID: ${widget.task!.id}');
      // Cargar los datos completos desde el backend (incluye empleados, vehículos, recursos, etc.)
      final taskCompleta = await _taskRepository.getTaskById(widget.task!.id);
      
      // Cargar las parcelas completas si hay IDs
      List<ParcelaModel> parcelasCompletas = [];
      if (taskCompleta.parcelaIds.isNotEmpty) {
        print('📍 Cargando ${taskCompleta.parcelaIds.length} parcelas...');
        try {
          final todasParcelas = await _parcelaRepository.getParcelas();
          parcelasCompletas = todasParcelas
              .where((p) => taskCompleta.parcelaIds.contains(p.id))
              .toList();
          print('✅ Parcelas cargadas: ${parcelasCompletas.length}');
        } catch (e) {
          print('⚠️ Error al cargar parcelas: $e');
        }
      }
      
      setState(() {
        _task = taskCompleta;
        _selectedParcelas = parcelasCompletas;
        _estadoDeTarea = _task.isCompleted ? 'Completada' : 'Pendiente';
        _fechas = '${DateFormat('dd/MM/yyyy').format(_task.inicio)} - ${DateFormat('dd/MM/yyyy').format(_task.fin)}';
      });
      
      print('✅ Datos completos cargados:');
      print('   - Parcelas: ${_selectedParcelas.length}');
      print('   - Empleados: ${_task.empleados.length}');
      print('   - Vehículos: ${_task.vehiculos.length}');
      print('   - Recursos: ${_task.recursos.length}');
    } catch (e) {
      print('❌ Error al cargar datos completos de la tarea: $e');
      // Mantener los datos básicos que ya tenemos
    }
  }
  
  Future<void> _loadData() async {
    try {
      // Cargar todos los datos en paralelo
      final results = await Future.wait([
        _empleadoRepository.getNombresEmpleados(),
        _vehiculoRepository.getNombresVehiculos(),
        _vehiculoRepository.getVehiculos(),
        _parcelaRepository.getFincas(),
        _parcelaRepository.getVariedades(),
        _taskRepository.getTiposTarea(),
        _empleadoRepository.getNombresAgricultores(), // Para responsables
      ]);
      
      setState(() {
        nombreEmpleados = List<String>.from(results[0] as List);
        possiblesVehiculos = List<String>.from(results[1] as List);
        final vehiculos = results[2] as List<VehiculoModel>;
        _vehiculosByNombre = {for (final v in vehiculos) v.nombre: v};
        _vehiculosByMatricula = {for (final v in vehiculos) v.matricula: v};
        possibleFields = List<String>.from(results[3] as List);
        possibleVariedades = List<String>.from(results[4] as List);
        possibleTypes = List<String>.from(results[5] as List);
        
        // Los responsables son solo agricultores
        possibleOfficers = List<String>.from(results[6] as List);
        
        // Si la tarea ya tiene un tipo, cargar recursos para ese tipo
        if (_task.type != null && _task.type!.isNotEmpty) {
          _loadRecursosByTipo(_task.type!);
        }
        
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingData = false;
      });
      
      // Mostrar error al usuario
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Carga los recursos filtrados por tipo de tarea
  Future<void> _loadRecursosByTipo(String tipoTarea) async {
    try {
      final recursos = await _recursoRepository.getNombresRecursosByTipo(tipoTarea);
      setState(() {
        possiblesRecursos = recursos;
      });
    } catch (e) {
      debugPrint('Error al cargar recursos por tipo: $e');
      // En caso de error, dejar la lista vacía
      setState(() {
        possiblesRecursos = [];
      });
    }
  }

  // Parse current _fechas string (which may have been changed via mostrarCalendario)
  // and return a DateTimeRange (fallback to _task.inicio/_task.fin on error).
  DateTimeRange _fechasToRange() {
    try {
      if (_fechas.contains(' - ')) {
        final parts = _fechas.split(' - ');
        final d1 = DateFormat('dd/MM/yyyy').parse(parts[0]);
        final d2 = DateFormat('dd/MM/yyyy').parse(parts[1]);
        return DateTimeRange(start: d1, end: d2);
      } else {
        final d = DateFormat('dd/MM/yyyy').parse(_fechas);
        return DateTimeRange(start: d, end: d);
      }
    } catch (e) {
      return DateTimeRange(start: _task.inicio, end: _task.fin);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
  }

  VehiculoModel? _findVehiculoModel(Vehiculo vehiculo) {
    if (vehiculo.matricula != null && vehiculo.matricula!.isNotEmpty) {
      final byMatricula = _vehiculosByMatricula[vehiculo.matricula!];
      if (byMatricula != null) return byMatricula;
    }
    return _vehiculosByNombre[vehiculo.nombre];
  }

  bool _isVehiculoAgricola(Vehiculo vehiculo) {
    final model = _findVehiculoModel(vehiculo);
    final tipo = (vehiculo.tipo?.isNotEmpty == true ? vehiculo.tipo : model?.tipo) ?? '';
    final normalized = _normalizeText(tipo);
    return normalized.contains('agricola');
  }

  String _vehiculoUnidad(Vehiculo vehiculo) {
    return _isVehiculoAgricola(vehiculo) ? 'h' : 'viajes';
  }

  Future<Map<String, int>?> _showValoresPorFechaDialog({
    required String title,
    required IconData icon,
    required String measureLabel,
    required String assignAllLabel,
    required DateTime startDay,
    required DateTime endDay,
    required Map<String, int> initialValues,
  }) async {
    final List<DateTime> dates = [];
    DateTime current = startDay;
    while (!current.isAfter(endDay)) {
      dates.add(current);
      current = current.add(const Duration(days: 1));
    }

    final Map<int, int> values = {};
    for (var i = 0; i < dates.length; i++) {
      final key = DateFormat('yyyy-MM-dd').format(dates[i]);
      values[i] = initialValues[key] ?? 0;
    }

    int? assignAll;

    return showDialog<Map<String, int>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(icon),
                  const SizedBox(width: 8),
                  Flexible(child: Text(title, softWrap: true)),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(assignAllLabel)),
                        DropdownButton<int?>(
                          value: assignAll,
                          items: [
                            const DropdownMenuItem<int?>(value: null, child: Text('-')),
                            ...List.generate(15, (i) => i).map((v) => DropdownMenuItem<int?>(value: v, child: Text(v.toString()))),
                          ],
                          onChanged: (v) {
                            setStateDialog(() {
                              assignAll = v;
                              if (v != null) {
                                for (var i = 0; i < dates.length; i++) {
                                  values[i] = v;
                                }
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Expanded(flex: 1, child: Center(child: Text('Día', style: TextStyle(fontWeight: FontWeight.bold)))),
                        Expanded(flex: 1, child: Center(child: Text(measureLabel, style: const TextStyle(fontWeight: FontWeight.bold)))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(dates.length, (index) {
                            final d = dates[index];
                            final label = DateFormat('d MMM').format(d);
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                children: [
                                  Expanded(flex: 1, child: Center(child: Text(label))),
                                  Expanded(
                                    flex: 1,
                                    child: Center(
                                      child: DropdownButton<int>(
                                        value: values[index],
                                        items: List.generate(15, (i) => i).map((v) => DropdownMenuItem(value: v, child: Text(v.toString()))).toList(),
                                        onChanged: (v) {
                                          if (v == null) return;
                                          setStateDialog(() {
                                            values[index] = v;
                                            assignAll = null;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () {
                        final Map<String, int> result = {};
                        for (var i = 0; i < dates.length; i++) {
                          final key = DateFormat('yyyy-MM-dd').format(dates[i]);
                          result[key] = values[i] ?? 0;
                        }
                        Navigator.of(context).pop(result);
                      },
                      child: const Text('Guardar'),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  void mostrarCalendario(BuildContext context) async {
    DateTimeRange? rangoFechas = await showDateRangePicker(
      context: context,
      locale: const Locale('es', 'ES'),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(
        start: DateTime.now(),
        end: DateTime.now(),
      ),
    );

    if (rangoFechas != null) {
      setState(() {
        // Siempre mostrar ambas fechas, incluso si son iguales
        _fechas = '${DateFormat('dd/MM/yyyy').format(rangoFechas.start)} - ${DateFormat('dd/MM/yyyy').format(rangoFechas.end)}';
      });
    }
  }

  void mostrarMensajeGuardado(BuildContext context) {
    final snackBar = SnackBar(
      content: Text(
        widget.task == null ? 
        'Tarea creada correctamente' : 'Tarea editada correctamente',
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      duration: const Duration(seconds: 2),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Widget buildDesplegable(String titulo, String? valorSeleccionado, List<String> opciones, void Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        DropdownButtonFormField<String>(
          value: opciones.contains(valorSeleccionado) ? valorSeleccionado : null,
          items: opciones
              .map((opcion) => DropdownMenuItem(value: opcion, child: Text(opcion)))
              .toList(),
          onChanged: onChanged,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
      ],
    );
  }



  // Genera un nombre descriptivo para una parcela
  String _buildParcelaName(ParcelaModel parcela) {
    final parts = <String>[
      parcela.finca,
      if (parcela.variedad != null) parcela.variedad!,
      if (parcela.paraje != null) parcela.paraje!,
      if (parcela.anoPlantacion != null) parcela.anoPlantacion!,
    ];
    return parts.join(' - ');
  }

  // Añade parcelas basándose en criterios parciales (pueden ser solo finca, finca+variedad, etc.)
  Future<void> _addParcelasByCriteria({
    String? finca,
    String? variedad,
    String? paraje,
    String? anoPlantacion,
  }) async {
    try {
      // Obtener todas las parcelas
      final todasLasParcelas = await _parcelaRepository.getParcelas();
      
      // Filtrar según criterios
      final parcelasFiltradas = todasLasParcelas.where((parcela) {
        if (finca != null && parcela.finca != finca) return false;
        if (variedad != null && parcela.variedad != variedad) return false;
        if (paraje != null && parcela.paraje != paraje) return false;
        if (anoPlantacion != null && parcela.anoPlantacion != anoPlantacion) return false;
        return true;
      }).toList();
      
      if (parcelasFiltradas.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se encontraron parcelas con esos criterios')),
          );
        }
        return;
      }
      
      setState(() {
        // Añadir parcelas que no estén ya seleccionadas
        for (var parcela in parcelasFiltradas) {
          if (!_selectedParcelas.any((p) => p.id == parcela.id)) {
            _selectedParcelas.add(parcela);
          }
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${parcelasFiltradas.length} parcela(s) añadida(s)')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al añadir parcelas: $e')),
        );
      }
    }
  }

  // Elimina una parcela de la selección
  void _removeParcela(int parcelaId) {
    setState(() {
      _selectedParcelas.removeWhere((p) => p.id == parcelaId);
    });
  }

  // Muestra el modal de selección de parcelas
  void _showParcelaSelectionModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _ParcelaSelectionModal(
          onAdd: _addParcelasByCriteria,
          parcelaRepository: _parcelaRepository,
        );
      },
    );
  }



  // Construye el botón y tabla de parcelas seleccionadas
  Widget buildParcelSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Parcelas', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              onPressed: _showParcelaSelectionModal,
              icon: const Icon(Icons.add),
              label: const Text('Añadir Parcelas'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Tabla de parcelas seleccionadas
        if (_selectedParcelas.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Center(
              child: Text(
                'No hay parcelas seleccionadas. Haz clic en "Añadir Parcelas" para seleccionar.',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                // Cabecera de la tabla
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 40,
                        child: Text('ID', 
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text('Nombre', 
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(
                        width: 80,
                        child: Text('Superficie', 
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 40), // Espacio para el botón de eliminar
                    ],
                  ),
                ),
                // Filas de la tabla
                ..._selectedParcelas.map((parcela) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 40,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text('${parcela.id}'),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              _buildParcelaName(parcela),
                              softWrap: true,
                              maxLines: null,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text(
                              '${parcela.superficie?.toStringAsFixed(2) ?? '-'} ha',
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 40,
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                            onPressed: () => _removeParcela(parcela.id),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                // Footer con resumen
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Total: ${_selectedParcelas.length} parcela(s)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        'Superficie total: ${_selectedParcelas.fold<double>(0.0, (sum, p) => sum + (p.superficie ?? 0.0)).toStringAsFixed(2)} ha',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget buildEmpleadoItem(Map<String, dynamic> empleado) {
    return ListTile(
      leading: CircleAvatar(
        child: Icon(empleado['foto']),
      ),
      title: Text(empleado['nombre']),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () {
              setState(() {
                if (empleado['horas'] > 0) empleado['horas']--;
              });
            },
          ),
          SizedBox(
            width: 50,
            child: TextField(
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              controller: TextEditingController(text: empleado['horas'].toString()),
              onChanged: (value) {
                setState(() {
                  empleado['horas'] = int.tryParse(value) ?? 0;
                });
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              setState(() {
                empleado['horas']++;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget buildListaEmpleados(List<HorasEmpleado> items, List<String> possibleOptions) {
    // group HorasEmpleado by Empleado.nombre
    final range = _fechasToRange();
    final startDay = DateTime(range.start.year, range.start.month, range.start.day);
    final endDay = DateTime(range.end.year, range.end.month, range.end.day);
    final Map<String, List<HorasEmpleado>> byEmpleado = {};
    for (var he in items) {
      final name = he.empleado.nombre;
      byEmpleado.putIfAbsent(name, () => []).add(he);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Empleados', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...byEmpleado.entries.map((entry) {
          final empName = entry.key;
          final records = entry.value;
          final empleado = records.isNotEmpty ? records.first.empleado : Empleado(nombre: empName, foto: Icon(Icons.face), contrato: 'temporal');
          final int totalHours = records.where((r) {
            final d = DateTime(r.fecha.year, r.fecha.month, r.fecha.day);
            return !d.isBefore(startDay) && !d.isAfter(endDay);
          }).fold<int>(0, (s, r) => s + r.horas);

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 0.0),
            minLeadingWidth: 0,
            leading: Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: CircleAvatar(
                radius: 25,
                child: Icon(empleado.foto.icon, size: 20),
              ),
            ),
            title: Text(empleado.nombre, overflow: TextOverflow.ellipsis),
            subtitle: Text('$totalHours h'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.more_time_rounded),
                  padding: const EdgeInsets.all(6.0),
                  constraints: const BoxConstraints(),
                  onPressed: () async {
                    final Map<String, int> initialValues = {};
                    DateTime cursor = startDay;
                    while (!cursor.isAfter(endDay)) {
                      final key = DateFormat('yyyy-MM-dd').format(cursor);
                      final rec = records.firstWhere(
                        (r) => _isSameDay(r.fecha, cursor),
                        orElse: () => HorasEmpleado(
                          id: 0,
                          empleado: empleado,
                          tarea: _task.id,
                          fecha: cursor,
                          horas: 0,
                          inicio: DateTime(cursor.year, cursor.month, cursor.day, 0, 0),
                          fin: DateTime(cursor.year, cursor.month, cursor.day, 0, 0),
                        ),
                      );
                      initialValues[key] = rec.horas;
                      cursor = cursor.add(const Duration(days: 1));
                    }

                    final result = await _showValoresPorFechaDialog(
                      title: 'Horas trabajadas de ${empleado.nombre}',
                      icon: Icons.access_time_rounded,
                      measureLabel: 'Horas',
                      assignAllLabel: 'Asignar las mismas horas a todos los días',
                      startDay: startDay,
                      endDay: endDay,
                      initialValues: initialValues,
                    );

                    if (result == null) return;

                    setState(() {
                      final Map<String, int> existingIndexByDay = {};
                      for (var idx = 0; idx < _task.empleados.length; idx++) {
                        final r = _task.empleados[idx];
                        if (r.empleado.nombre == empleado.nombre) {
                          final key = DateFormat('yyyy-MM-dd').format(r.fecha);
                          existingIndexByDay[key] = idx;
                        }
                      }

                      result.forEach((key, horas) {
                        final d = DateTime.parse(key);
                        final newRecord = HorasEmpleado(
                          id: DateTime.now().millisecondsSinceEpoch + d.day,
                          empleado: empleado,
                          tarea: _task.id,
                          fecha: d,
                          horas: horas,
                          inicio: DateTime(d.year, d.month, d.day, 9, 0),
                          fin: DateTime(d.year, d.month, d.day, 9 + (horas > 0 ? horas : 0), 0),
                        );

                        if (existingIndexByDay.containsKey(key)) {
                          final idx = existingIndexByDay[key]!;
                          _task.empleados[idx] = newRecord;
                        } else {
                          _task.empleados.add(newRecord);
                        }
                      });

                      _task.empleados.removeWhere((r) {
                        if (r.empleado.nombre != empleado.nombre) return false;
                        final d = DateTime(r.fecha.year, r.fecha.month, r.fecha.day);
                        return d.isBefore(startDay) || d.isAfter(endDay);
                      });
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  padding: const EdgeInsets.all(6.0),
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    setState(() {
                      _task.empleados.removeWhere((r) => r.empleado.nombre == empleado.nombre);
                    });
                  },
                ),
              ],
            ),
          );
        }),
        Center(
          child: TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  String? selectedItem;
                  return AlertDialog(
                    title: Text('Selecciona un empleado'),
                    content: DropdownButtonFormField<String>(
                      items: possibleOptions.map((opcion) => DropdownMenuItem(value: opcion, child: Text(opcion))).toList(),
                      onChanged: (value) {
                        selectedItem = value;
                      },
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () {
                          if (selectedItem != null) {
                            setState(() {
                              // Buscar empleado por nombre en la lista cargada
                              final range = _fechasToRange();
                              DateTime cur = DateTime(range.start.year, range.start.month, range.start.day);
                              DateTime last = DateTime(range.end.year, range.end.month, range.end.day);
                              while (!cur.isAfter(last)) {
                                _task.empleados.add(HorasEmpleado(
                                  id: DateTime.now().millisecondsSinceEpoch + cur.day, 
                                  empleado: Empleado(
                                    nombre: selectedItem!, 
                                    foto: const Icon(Icons.person), 
                                    contrato: 'temporal'
                                  ), 
                                  tarea: _task.id, 
                                  fecha: cur, 
                                  horas: 0, 
                                  inicio: DateTime(cur.year, cur.month, cur.day, 0, 0), 
                                  fin: DateTime(cur.year, cur.month, cur.day, 0, 0)
                                ));
                                cur = cur.add(const Duration(days: 1));
                              }
                            });
                          }
                          Navigator.of(context).pop();
                        },
                        child: const Text('Añadir'),
                      ),
                    ],
                  );
                },
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300],
            ),
            child: const Text('Añadir más empleados', style: TextStyle(color: Colors.black)),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget buildListaVehiculos(List<Vehiculo> items, List<String> possibleOptions) {
    final range = _fechasToRange();
    final startDay = DateTime(range.start.year, range.start.month, range.start.day);
    final endDay = DateTime(range.end.year, range.end.month, range.end.day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Vehículos', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...items.map((item) {
          final vehiculoModel = _findVehiculoModel(item);
          if (item.matricula == null || item.matricula!.isEmpty) {
            item.matricula = vehiculoModel?.matricula;
          }
          if (item.tipo == null || item.tipo!.isEmpty) {
            item.tipo = vehiculoModel?.tipo;
          }

          // Mostrar como "nombre" o "nombre con accesorio"
          final displayText = item.accesorioNombre != null && item.accesorioNombre!.isNotEmpty
              ? '${item.nombre} con ${item.accesorioNombre}'
              : item.nombre;

          int totalUsage = 0;
          item.valores.forEach((fechaStr, value) {
            try {
              final d = DateTime.parse(fechaStr);
              final day = DateTime(d.year, d.month, d.day);
              if (!day.isBefore(startDay) && !day.isAfter(endDay)) {
                totalUsage += value;
              }
            } catch (_) {}
          });
          final unidad = _vehiculoUnidad(item);
          final tituloValores = _isVehiculoAgricola(item)
              ? 'Horas de uso de ${item.nombre}'
              : 'Viajes al almacén de ${item.nombre}';
          final etiquetaMedida = _isVehiculoAgricola(item) ? 'Horas' : 'Viajes';
          final etiquetaAsignar = _isVehiculoAgricola(item)
              ? 'Asignar las mismas horas a todos los días'
              : 'Asignar los mismos viajes a todos los días';
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: 4),
                CircleAvatar(
                  radius: 25,
                  child: Icon(Icons.directions_car)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayText, overflow: TextOverflow.ellipsis),
                      Text('$totalUsage $unidad', style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_time_rounded),
                  padding: const EdgeInsets.all(6.0),
                  constraints: const BoxConstraints(),
                  onPressed: () async {
                    final Map<String, int> initialValues = {};
                    DateTime cursor = startDay;
                    while (!cursor.isAfter(endDay)) {
                      final key = DateFormat('yyyy-MM-dd').format(cursor);
                      initialValues[key] = item.valores[key] ?? 0;
                      cursor = cursor.add(const Duration(days: 1));
                    }

                    final result = await _showValoresPorFechaDialog(
                      title: tituloValores,
                      icon: Icons.more_time_rounded,
                      measureLabel: etiquetaMedida,
                      assignAllLabel: etiquetaAsignar,
                      startDay: startDay,
                      endDay: endDay,
                      initialValues: initialValues,
                    );

                    if (result == null) return;

                    setState(() {
                      item.valores = result;
                    });
                  },
                ),
                // Botón para agregar/cambiar accesorio
                IconButton(
                  icon: Icon(
                    item.accesorioId != null ? Icons.edit : Icons.add_circle_outline,
                  ),
                  onPressed: () async {
                    // Mostrar modal con lista de accesorios
                    final accesoriosVehiculo = await _accesorioRepository.getNombresAccesorios();
                    if (!mounted) return;
                    
                    showDialog(
                      context: context,
                      builder: (BuildContext dialogContext) {
                        String? selectedAccesorio;
                        return AlertDialog(
                          title: const Text('Selecciona un accesorio'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DropdownButtonFormField<String>(
                                value: item.accesorioNombre,
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('Sin accesorio')),
                                  ...accesoriosVehiculo.map((acc) => 
                                    DropdownMenuItem(value: acc, child: Text(acc))
                                  ),
                                ],
                                onChanged: (value) {
                                  selectedAccesorio = value;
                                },
                                decoration: const InputDecoration(border: OutlineInputBorder()),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(dialogContext).pop(),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () async {
                                if (selectedAccesorio != null) {
                                  // Obtener el ID del accesorio seleccionado
                                  final accesorios = await _accesorioRepository.getAccesorios();
                                  final accesorioModel = accesorios.firstWhere(
                                    (a) => a.nombre == selectedAccesorio,
                                    orElse: () => accesorios.first,
                                  );
                                  
                                  setState(() {
                                    item.accesorioId = accesorioModel.id;
                                    item.accesorioNombre = selectedAccesorio;
                                  });
                                } else {
                                  setState(() {
                                    item.accesorioId = null;
                                    item.accesorioNombre = null;
                                  });
                                }
                                Navigator.of(dialogContext).pop();
                              },
                              child: const Text('Guardar'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    setState(() {
                      _task.vehiculos.remove(item);
                    });
                  },
                ),
              ],
            ),
          );
        }),
        Center(
          child: TextButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300],
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  String? selectedItem;
                  return AlertDialog(
                    title: const Text('Selecciona un vehículo'),
                    content: DropdownButtonFormField<String>(
                      items: possibleOptions
                      .map((opcion) => DropdownMenuItem(value: opcion, child: Text(opcion)))
                      .toList(),
                      onChanged: (value) {
                        selectedItem = value;
                      },
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () {
                          if (selectedItem != null) {
                            final selectedVehiculoModel = _vehiculosByNombre[selectedItem!];
                            setState(() {
                              _task.vehiculos.add(
                                Vehiculo(
                                  nombre: selectedItem!,
                                  matricula: selectedVehiculoModel?.matricula,
                                  tipo: selectedVehiculoModel?.tipo,
                                  valores: <String, int>{},
                                ),
                              );
                            });
                          }
                          Navigator.of(context).pop();
                        },
                        child: const Text('Añadir'),
                      ),
                    ],
                  );
                },
              );
            },
            child: const Text('Añadir más vehículos', style: TextStyle(color: Colors.black)),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget buildListaRecursos(List<RegistroCantidadRecursos> items, List<String> possibleOptions) {
    final range = _fechasToRange();
    final startDay = DateTime(range.start.year, range.start.month, range.start.day);
    final endDay = DateTime(range.end.year, range.end.month, range.end.day);

    final Map<String, List<RegistroCantidadRecursos>> byRec = {};
    for (var r in items) {
      byRec.putIfAbsent(r.recurso.nombre, () => []).add(r);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recursos', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...byRec.entries.map((entry) {
          final recName = entry.key;
          final records = entry.value;
          final recurso = records.isNotEmpty ? records.first.recurso : Recurso(nombre: recName);
          final int total = records.where((r) {
            final d = DateTime(r.fecha.year, r.fecha.month, r.fecha.day);
            return !d.isBefore(startDay) && !d.isAfter(endDay);
          }).fold<int>(0, (s, r) => s + r.cantidad);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: 4),
                CircleAvatar(radius: 25, child: Icon(recurso.foto.icon)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(recurso.nombre), Text('$total ${recurso.unidades}', style: const TextStyle(fontSize: 12, color: Colors.black54))])),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  padding: const EdgeInsets.all(6.0),
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    // modal similar to previous but using flat records
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        List<DateTime> dates = [];
                        DateTime cur = startDay;
                        while (!cur.isAfter(endDay)) {
                          dates.add(cur);
                          cur = cur.add(const Duration(days: 1));
                        }

                        Map<int,int> values = {};
                        for (var i=0;i<dates.length;i++) {
                          final d = dates[i];
                          final rec = records.firstWhere((r) => _isSameDay(r.fecha, d), orElse: () => RegistroCantidadRecursos(id: 0, recurso: recurso, tarea: _task.id, fecha: d, cantidad: 0));
                          values[i] = rec.cantidad;
                        }

                        final totalController = TextEditingController();
                        final totalFocus = FocusNode();
                        final assignController = TextEditingController(text: '-');
                        final assignFocus = FocusNode();
                        bool isListenerAttached = false;
                        final dayControllers = List<TextEditingController>.generate(dates.length, (i) => TextEditingController(text: (values[i] ?? 0).toString()));

                        return StatefulBuilder(
                          builder: (context, setStateDialog) {
                            if (!isListenerAttached) {
                              isListenerAttached = true;
                              totalFocus.addListener(() {
                                if (totalFocus.hasFocus) {
                                  totalController.selection = TextSelection(baseOffset: 0, extentOffset: totalController.text.length);
                                } else {
                                  final parsed = int.tryParse(totalController.text);
                                  if (parsed == null) return;
                                  final total = parsed;
                                  if (dates.isEmpty) return;
                                  final base = total ~/ dates.length;
                                  final rem = total % dates.length;
                                  setStateDialog(() {
                                    for (var i = 0; i < dates.length; i++) {
                                      final val = base + (i < rem ? 1 : 0);
                                      values[i] = val;
                                      dayControllers[i].text = val.toString();
                                    }
                                    assignController.text = '-';
                                  });
                                }
                              });

                              assignFocus.addListener(() {
                                if (assignFocus.hasFocus) {
                                  assignController.selection = TextSelection(baseOffset: 0, extentOffset: assignController.text.length);
                                } else {
                                  final parsed = int.tryParse(assignController.text);
                                  if (parsed == null) return;
                                  final val = parsed;
                                  setStateDialog(() {
                                    for (var i = 0; i < dates.length; i++) {
                                      values[i] = val;
                                      dayControllers[i].text = val.toString();
                                    }
                                    totalController.text = '-';
                                  });
                                }
                              });
                            }

                            return AlertDialog(
                              title: Row(children: [const Icon(Icons.add_shopping_cart), const SizedBox(width: 8), Flexible(child: Text('Establecer cantidad de ${recurso.nombre}', softWrap: true))]),
                              content: SizedBox(
                                width: double.maxFinite,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(children: [const Expanded(child: Text('Establecer cantidad total y repartir entre todos los días')), const SizedBox(width: 8), SizedBox(width: 100, child: TextField(controller: totalController, focusNode: totalFocus, keyboardType: TextInputType.number, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Total', isDense: true), onChanged: (v) { if (assignController.text != '-') assignController.text = '-'; },),),]),
                                    const SizedBox(height: 12),
                                    Row(children: [const Expanded(child: Text('Asignar las mismas cantidades a todos los días')), const SizedBox(width: 8), SizedBox(width: 100, child: TextField(controller: assignController, focusNode: assignFocus, keyboardType: TextInputType.number, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, hintText: '-'), onChanged: (v) { if (totalController.text != '-') totalController.text = '-'; setStateDialog(() { final val = int.tryParse(v) ?? 0; for (var i = 0; i < dates.length; i++) { values[i] = val; dayControllers[i].text = val.toString(); } }); },),),]),
                                    const SizedBox(height: 12),
                                    Row(children: [const Expanded(flex: 1, child: Center(child: Text('Día', style: TextStyle(fontWeight: FontWeight.bold)))), Expanded(flex: 1, child: Center(child: Text(recurso.unidades, style: const TextStyle(fontWeight: FontWeight.bold))))]),
                                    const SizedBox(height: 8),
                                                                  Flexible(
                                                                    child: SingleChildScrollView(
                                                                      child: Column(
                                                                        mainAxisSize: MainAxisSize.min,
                                                                        children: List.generate(dates.length, (index) {
                                                                          final d = dates[index];
                                                                          final label = DateFormat('d MMM').format(d);
                                                                          return Padding(
                                                                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                                                                            child: Row(
                                                                              children: [
                                                                                Expanded(flex: 1, child: Center(child: Text(label))),
                                                                                Expanded(
                                                                                  flex: 1,
                                                                                  child: Center(
                                                                                    child: SizedBox(
                                                                                      width: 100,
                                                                                      child: TextField(
                                                                                        controller: dayControllers[index],
                                                                                        keyboardType: TextInputType.number,
                                                                                        textAlign: TextAlign.center,
                                                                                        decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                                                                                        onChanged: (v) {
                                                                                          setStateDialog(() {
                                                                                            values[index] = int.tryParse(v) ?? 0;
                                                                                          });
                                                                                        },
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          );
                                                                        }),
                                                                      ),
                                                                    ),
                                                                  ),
                                  ],
                                ),
                              ),
                              actions: [Row(mainAxisAlignment: MainAxisAlignment.center, children: [TextButton(onPressed: () => Navigator.of(context).pop(), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Cancelar'),), const SizedBox(width: 12), TextButton(onPressed: () {
                                final Map<DateTime,int> newMap = {};
                                for (var i = 0; i < dates.length; i++) {
                                  newMap[dates[i]] = values[i] ?? 0;
                                }
                                setState(() {
                                  // map existing recurso records to their indices to preserve order
                                  final Map<String,int> existingIdx = {};
                                  for (var idx = 0; idx < _task.recursos.length; idx++) {
                                    final r = _task.recursos[idx];
                                    if (r.recurso.nombre == recurso.nombre) {
                                      final key = '${r.fecha.year}-${r.fecha.month}-${r.fecha.day}';
                                      existingIdx[key] = idx;
                                    }
                                  }

                                  for (var i = 0; i < dates.length; i++) {
                                    final d = dates[i];
                                    final key = '${d.year}-${d.month}-${d.day}';
                                    final newRec = RegistroCantidadRecursos(id: DateTime.now().millisecondsSinceEpoch + i, recurso: recurso, tarea: _task.id, fecha: d, cantidad: newMap[d] ?? 0);
                                    if (existingIdx.containsKey(key)) {
                                      _task.recursos[existingIdx[key]!] = newRec;
                                    } else {
                                      _task.recursos.add(newRec);
                                    }
                                  }

                                  // remove any recurso records outside the range
                                  _task.recursos.removeWhere((r) {
                                    if (r.recurso.nombre != recurso.nombre) return false;
                                    final d = DateTime(r.fecha.year, r.fecha.month, r.fecha.day);
                                    return d.isBefore(startDay) || d.isAfter(endDay);
                                  });
                                });
                                Navigator.of(context).pop();
                              }, child: const Text('Guardar'),),],),],);
                          },
                        );
                      },
                    );
                  },
                ),
                IconButton(icon: const Icon(Icons.delete), onPressed: () { setState(() { _task.recursos.removeWhere((r) => r.recurso.nombre == recurso.nombre); }); }),
              ],
            ),
          );
        }),
        Center(child: TextButton(onPressed: () {
          showDialog(context: context, builder: (BuildContext context) {
            String? selectedItem;
            return AlertDialog(
              title: const Text('Selecciona un recurso'),
              content: DropdownButtonFormField<String>(items: possibleOptions.map((opcion) => DropdownMenuItem(value: opcion, child: Text(opcion))).toList(), onChanged: (value) { selectedItem = value; }, decoration: const InputDecoration(border: OutlineInputBorder()),),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Cancelar')),
                TextButton(onPressed: () async {
                  if (selectedItem != null) {
                    // Buscar el recurso en el repositorio para obtener sus unidades
                    final recursosModels = await _recursoRepository.getRecursos();
                    final recursoModel = recursosModels.firstWhere(
                      (r) => r.nombre == selectedItem,
                      orElse: () => throw Exception('Recurso no encontrado: $selectedItem'),
                    );
                    
                    setState(() {
                      final range = _fechasToRange();
                      DateTime cur = DateTime(range.start.year, range.start.month, range.start.day);
                      DateTime last = DateTime(range.end.year, range.end.month, range.end.day);
                      final rec = Recurso(nombre: selectedItem!, unidades: recursoModel.unidadConsumo);
                      int i = 0;
                      while (!cur.isAfter(last)) {
                        _task.recursos.add(RegistroCantidadRecursos(id: DateTime.now().millisecondsSinceEpoch + i, recurso: rec, tarea: _task.id, fecha: cur, cantidad: 0));
                        cur = cur.add(const Duration(days: 1));
                        i++;
                      }
                    });
                  }
                  Navigator.of(context).pop();
                }, child: const Text('Añadir')),
              ],
            );
          });
        }, style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[300]), child: const Text('Añadir más recursos', style: TextStyle(color: Colors.black)),),),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task != null ? 'Editar tarea' : 'Crear tarea'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildDesplegable('Tipo de tarea', _task.type, possibleTypes, (value) {
              setState(() => _task.type = value);
              if (value != null && value.isNotEmpty) {
                _loadRecursosByTipo(value);
              }
            }),
            // Campo de nombre de la tarea
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nombre de la tarea (opcional)', 
                  style: TextStyle(fontWeight: FontWeight.bold)),
                TextField(
                  key: ValueKey(_task.nombre),
                  controller: TextEditingController(text: _task.nombre ?? ''),
                  maxLength: 50,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Ej: Poda de invierno 2026',
                    counterText: '', // Oculta el contador de caracteres
                  ),
                  onChanged: (value) {
                    _task.nombre = value.isEmpty ? null : value;
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
            buildParcelSelector(),
            buildDesplegable('Estado de la tarea', _estadoDeTarea, ['Pendiente', 'Completada'], (value) => setState(() => _estadoDeTarea = value)),
            buildDesplegable('Responsable', _task.officer, possibleOfficers, (value) => setState(() => _task.officer = value)),
            Text('Fechas', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              readOnly: true,
              controller: TextEditingController(text: _fechas),
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => mostrarCalendario(context),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            buildListaEmpleados(_task.empleados, nombreEmpleados),
            buildListaVehiculos(_task.vehiculos, possiblesVehiculos),
            buildListaRecursos(_task.recursos, possiblesRecursos),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 12.0),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () async {
                // Validar campos requeridos
                if (_task.type == null || _task.type!.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Debe seleccionar un tipo de tarea'), backgroundColor: Colors.orange),
                  );
                  return;
                }
                
                if (_selectedParcelas.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Debe seleccionar al menos una parcela'), backgroundColor: Colors.orange),
                  );
                  return;
                }
                
                // Actualizar fechas del task
                final range = _fechasToRange();
                _task.inicio = range.start;
                _task.fin = range.end;
                _task.isCompleted = _estadoDeTarea == 'Completada';
                
                // Mostrar indicador de carga
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return const Center(child: CircularProgressIndicator());
                  },
                );
                
                try {
                  print('═══════════════════════════════════════════════════════');
                  print('🔍 INICIO DEL PROCESO DE GUARDADO');
                  print('═══════════════════════════════════════════════════════');
                  
                  // Obtener todos los IDs de parcelas seleccionadas (verificar que no sean null)
                  print('\n📦 PASO 1: Procesando parcelas...');
                  print('Parcelas seleccionadas: ${_selectedParcelas.length}');
                  final List<int> allParcelaIds = _selectedParcelas
                      .where((p) => p.id != null)
                      .map((p) => p.id!)
                      .toList();
                  print('✅ IDs de parcelas válidos: $allParcelaIds');
                  
                  if (allParcelaIds.isEmpty) {
                    throw Exception('No hay parcelas válidas seleccionadas');
                  }
                  
                  // Construir gastos de empleados
                  print('\n👥 PASO 2: Procesando empleados...');
                  print('Total empleados en tarea: ${_task.empleados.length}');
                  final empleadosModels = await _empleadoRepository.getEmpleados();
                  print('Total empleados disponibles: ${empleadosModels.length}');
                  
                  final Map<int, Map<String, dynamic>> empleadosData = {};
                  for (var i = 0; i < _task.empleados.length; i++) {
                    try {
                      final horasEmpleado = _task.empleados[i];
                      print('\n  Empleado [$i]: ${horasEmpleado.empleado.nombre}');
                      print('    - Fecha: ${horasEmpleado.fecha}');
                      print('    - Horas: ${horasEmpleado.horas} (tipo: ${horasEmpleado.horas.runtimeType})');
                      
                      // Buscar el ID del empleado por nombre
                      final empleadoModel = empleadosModels.firstWhere(
                        (e) => e.nombre == horasEmpleado.empleado.nombre,
                        orElse: () => throw Exception('Empleado no encontrado: ${horasEmpleado.empleado.nombre}'),
                      );
                      print('    - ID encontrado: ${empleadoModel.id} (tipo: ${empleadoModel.id.runtimeType})');
                      print('    - Cargo: ${empleadoModel.cargo}');
                      
                      // Validar que el ID del empleado no sea null o 0
                      if (empleadoModel.id == 0) {
                        throw Exception('ID inválido para empleado: ${horasEmpleado.empleado.nombre}');
                      }
                      
                      String fechaStr = horasEmpleado.fecha.toIso8601String().split('T')[0];
                      if (!empleadosData.containsKey(empleadoModel.id)) {
                        empleadosData[empleadoModel.id] = {
                          'cargo': empleadoModel.cargo ?? 'Sin cargo',
                          'valores': <String, int>{}, // Cambiar a int explícitamente
                        };
                        print('    - Creado nuevo registro para empleado ID ${empleadoModel.id}');
                      }
                      (empleadosData[empleadoModel.id]!['valores'] as Map<String, int>)[fechaStr] = horasEmpleado.horas;
                      print('    ✅ Agregado: $fechaStr -> ${horasEmpleado.horas}h');
                    } catch (e, stackTrace) {
                      print('    ❌ ERROR en empleado [$i]: $e');
                      print('    Stack: ${stackTrace.toString().split('\n').take(3).join('\n')}');
                      rethrow;
                    }
                  }
                  print('\n✅ Empleados procesados correctamente');
                  print('Estructura empleadosData: ${empleadosData.map((k,v) => MapEntry(k, {'cargo': v['cargo'], 'valores_count': (v['valores'] as Map).length}))}');
                  
                  // Construir gastos de vehíedculos
                  print('\n🚜 PASO 3: Procesando vehículos...');
                  print('Total vehículos en tarea: ${_task.vehiculos.length}');
                  final vehiculosModels = await _vehiculoRepository.getVehiculos();
                  print('Total vehículos disponibles: ${vehiculosModels.length}');
                  
                  final List<Map<String, dynamic>> gastosVehiculos = [];
                  for (var i = 0; i < _task.vehiculos.length; i++) {
                    try {
                      final vehiculo = _task.vehiculos[i];
                      print('\n  Vehículo [$i]: ${vehiculo.nombre}');
                      print('    - Matrícula: ${vehiculo.matricula}');
                      print('    - Accesorio ID: ${vehiculo.accesorioId}');
                      print('    - Valores: ${vehiculo.valores}');
                      
                      // Buscar el vehíedculo por nombre
                      final vehiculoModel = vehiculosModels.firstWhere(
                        (v) => v.nombre == vehiculo.nombre || (vehiculo.matricula != null && vehiculo.matricula!.isNotEmpty && v.matricula == vehiculo.matricula),
                        orElse: () => throw Exception('Vehíedculo no encontrado: ${vehiculo.nombre}'),
                      );
                      print('    - ID encontrado: ${vehiculoModel.id}');
                      print('    - Matríedcula encontrada: ${vehiculoModel.matricula}');

                      final Map<String, int> valoresVehiculo = <String, int>{};
                      vehiculo.valores.forEach((fecha, valor) {
                        valoresVehiculo[fecha] = valor;
                      });
                      
                      final Map<String, dynamic> vehiculoData = {
                        'id': vehiculoModel.id,  // Usar ID del vehículo (requerido)
                        'matricula': vehiculoModel.matricula,  // Matrícula es requerida por el backend
                        'valores': valoresVehiculo,
                      };
                      if (vehiculo.accesorioId != null) {
                        vehiculoData['accesorio'] = {'id': vehiculo.accesorioId};
                        print('    - Con accesorio ID: ${vehiculo.accesorioId}');
                      }
                      gastosVehiculos.add(vehiculoData);
                      print('    ✅ Vehículo agregado correctamente');
                    } catch (e, stackTrace) {
                      print('    ❌ ERROR en vehículo [$i]: $e');
                      print('    Stack: ${stackTrace.toString().split('\n').take(3).join('\n')}');
                      rethrow;
                    }
                  }
                  print('\n✅ Vehículos procesados correctamente');
                  
                  // Construir gastos de recursos
                  print('\n📦 PASO 4: Procesando recursos...');
                  print('Total recursos en tarea: ${_task.recursos.length}');
                  final recursosModels = await _recursoRepository.getRecursos();
                  print('Total recursos disponibles: ${recursosModels.length}');
                  
                  final Map<int, Map<String, double>> recursosValues = {};
                  for (var i = 0; i < _task.recursos.length; i++) {
                    try {
                      final registroRecurso = _task.recursos[i];
                      print('\n  Recurso [$i]: ${registroRecurso.recurso.nombre}');
                      print('    - Fecha: ${registroRecurso.fecha}');
                      print('    - Cantidad: ${registroRecurso.cantidad} (tipo: ${registroRecurso.cantidad.runtimeType})');
                      
                      // Buscar el ID del recurso por nombre
                      final recursoModel = recursosModels.firstWhere(
                        (r) => r.nombre == registroRecurso.recurso.nombre,
                        orElse: () => throw Exception('Recurso no encontrado: ${registroRecurso.recurso.nombre}'),
                      );
                      print('    - ID encontrado: ${recursoModel.id}');
                      
                      String fechaStr = registroRecurso.fecha.toIso8601String().split('T')[0];
                      if (!recursosValues.containsKey(recursoModel.id)) {
                        recursosValues[recursoModel.id] = {};
                        print('    - Creado nuevo registro para recurso ID ${recursoModel.id}');
                      }
                      recursosValues[recursoModel.id]![fechaStr] = registroRecurso.cantidad.toDouble();
                      print('    ✅ Agregado: $fechaStr -> ${registroRecurso.cantidad}');
                    } catch (e, stackTrace) {
                      print('    ❌ ERROR en recurso [$i]: $e');
                      print('    Stack: ${stackTrace.toString().split('\n').take(3).join('\n')}');
                      rethrow;
                    }
                  }
                  print('\n✅ Recursos procesados correctamente');
                  
                  // Obtener ID del responsable si estíe1 seleccionado
                  int? idEmpleadoResponsable;
                  if (_task.officer != null && _task.officer!.isNotEmpty) {
                    try {
                      final responsableModel = empleadosModels.firstWhere(
                        (e) => e.nombre == _task.officer,
                      );
                      idEmpleadoResponsable = responsableModel.id;
                    } catch (e) {
                      // Si no se encuentra, ignorar
                    }
                  }
                  
                  // Crear el payload para el API
                  print('\n📋 PASO 6: Construyendo payload...');
                  print('Datos de la tarea:');
                  print('  - Tipo: ${_task.type}');
                  print('  - Nombre: ${_task.nombre ?? "(sin nombre)"}');
                  print('  - Fecha inicio: ${_task.inicio.toIso8601String().split('T')[0]}');
                  print('  - Fecha fin: ${_task.fin.toIso8601String().split('T')[0]}');
                  print('  - Responsable: ${_task.officer ?? "(ninguno)"}');
                  print('  - ID responsable: $idEmpleadoResponsable');
                  print('  - Completada: ${_task.isCompleted}');
                  print('  - Parcelas: ${allParcelaIds.length} IDs');
                  
                  final Map<String, dynamic> tareaData = {
                    'tipo_tarea': _task.type!,
                    'nombre': _task.nombre, // Nombre descriptivo de la tarea
                    'parcelas': allParcelaIds.map((id) => {'id': id}).toList(),
                    'fecha_inicio': _task.inicio.toIso8601String().split('T')[0],
                    'fecha_final': _task.fin.toIso8601String().split('T')[0],
                    'responsable': _task.officer,
                    'id_empleado_responsable': idEmpleadoResponsable,
                    'completada': _task.isCompleted,
                  };
                  
                  // Añadir gastos de empleados
                  print('\n📝 Agregando gastos al payload...');
                  if (empleadosData.isNotEmpty) {
                    print('  ✅ Gastos empleados: ${empleadosData.length} empleados');
                    
                    // Construir lista con validación detallada
                    final gastosEmpleadosList = <Map<String, dynamic>>[];
                    for (var entry in empleadosData.entries) {
                      print('     🔍 Procesando empleado ID: ${entry.key}');
                      print('        - cargo: ${entry.value['cargo']} (${entry.value['cargo'].runtimeType})');
                      print('        - valores: ${entry.value['valores']} (${entry.value['valores'].runtimeType})');
                      
                      final gastoEmpleado = {
                        'id': entry.key,
                        'cargo': entry.value['cargo'],
                        'valores': entry.value['valores'],
                      };
                      
                      // Validar que ningún campo sea null
                      if (entry.key == null) {
                        print('        ❌ ERROR: ID es null');
                      }
                      if (entry.value['cargo'] == null) {
                        print('        ❌ ERROR: cargo es null');
                      }
                      if (entry.value['valores'] == null) {
                        print('        ❌ ERROR: valores es null');
                      }
                      
                      gastosEmpleadosList.add(gastoEmpleado);
                      print('        ✅ Gasto empleado construido: $gastoEmpleado');
                    }
                    
                    tareaData['gastos_empleados'] = gastosEmpleadosList;
                    print('     📦 Lista final gastos_empleados: $gastosEmpleadosList');
                  } else {
                    print('  ⚠️ Sin gastos de empleados');
                  }
                  
                  // Añadir gastos de vehíedculos
                  if (gastosVehiculos.isNotEmpty) {
                    print('  ✅ Gastos vehículos: ${gastosVehiculos.length} registros');
                    tareaData['gastos_vehiculos'] = gastosVehiculos;
                    print('     Estructura final: $gastosVehiculos');
                  } else {
                    print('  ⚠️ Sin gastos de vehículos');
                  }
                  
                  // Añadir gastos de recursos
                  if (recursosValues.isNotEmpty) {
                    print('  ✅ Gastos recursos: ${recursosValues.length} recursos');
                    tareaData['gastos_recursos'] = recursosValues.entries.map((entry) => {
                      'id': entry.key,
                      'valores': entry.value,
                    }).toList();
                    print('     Estructura final: ${tareaData['gastos_recursos']}');
                  } else {
                    print('  ⚠️ Sin gastos de recursos');
                  }
                  
                  print('\n📤 PASO 7: Enviando al API...');
                  print('Mode: ${widget.task == null ? "CREAR" : "ACTUALIZAR"}');
                  print('════════════════════════════════════════════════════════');
                  print('📦 PAYLOAD COMPLETO FINAL - ANÁLISIS DETALLADO:');
                  print('════════════════════════════════════════════════════════');
                  
                  tareaData.forEach((key, value) {
                    print('\n🔑 Campo: "$key"');
                    print('   Tipo: ${value.runtimeType}');
                    print('   Valor: $value');
                    
                    // Si es una lista, mostrar detalles de cada elemento
                    if (value is List) {
                      print('   📋 Lista con ${value.length} elementos:');
                      for (var i = 0; i < value.length; i++) {
                        final item = value[i];
                        print('      [$i] Tipo: ${item.runtimeType}');
                        print('      [$i] Valor: $item');
                        
                        // Si el elemento es un Map, mostrar sus campos
                        if (item is Map) {
                          item.forEach((k, v) {
                            print('         • $k: $v (${v.runtimeType})');
                            if (v == null) {
                              print('           ⚠️ ESTE VALOR ES NULL');
                            }
                          });
                        }
                      }
                    }
                  });
                  
                  print('════════════════════════════════════════════════════════\n');
                  
                  // Llamar al servicio directamente enviando el payload crudo
                  // No construimos TareaModel porque el payload ya tiene el formato correcto del API
                  final tareaService = TareaService();
                  int tareaId;
                  if (widget.task == null) {
                    // Crear nueva tarea
                    print('  → Llamando a createTareaFromPayload()...');
                    tareaId = await tareaService.createTareaFromPayload(tareaData);
                    print('  ✅ Tarea creada exitosamente con ID: $tareaId');
                  } else {
                    // Actualizar tarea existente
                    print('  → Llamando a updateTareaFromPayload(${_task.id})...');
                    tareaId = await tareaService.updateTareaFromPayload(_task.id, tareaData);
                    print('  ✅ Tarea actualizada exitosamente con ID: $tareaId');
                  }
                  
                  print('\n═══════════════════════════════════════════════════════');
                  print('✅ PROCESO COMPLETADO CON ÉXITO');
                  print('═══════════════════════════════════════════════════════\n');
                  
                  if (!mounted) return;
                  Navigator.pop(context); // Cerrar diíe1logo de carga
                  Navigator.pop(context, _task); // Volver a la pantalla anterior
                  mostrarMensajeGuardado(context);
                  
                } catch (e, stackTrace) {
                  print('\n═══════════════════════════════════════════════════════');
                  print('❌ ERROR EN EL PROCESO DE GUARDADO');
                  print('═══════════════════════════════════════════════════════');
                  print('Error: $e');
                  print('Tipo de error: ${e.runtimeType}');
                  print('\nStack trace:');
                  print(stackTrace.toString().split('\n').take(10).join('\n'));
                  print('═══════════════════════════════════════════════════════\n');
                  
                  if (!mounted) return;
                  Navigator.pop(context); // Cerrar diíe1logo de carga
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al guardar tarea: $e'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text('Guardar', style: TextStyle(color: Colors.black)),
            ),
          ),
        ),
      ),
    );
  }
}

// Modal de selección de parcelas con desplegables jerárquicos
class _ParcelaSelectionModal extends StatefulWidget {
  final Function({String? finca, String? variedad, String? paraje, String? anoPlantacion}) onAdd;
  final ParcelaRepository parcelaRepository;

  const _ParcelaSelectionModal({
    required this.onAdd,
    required this.parcelaRepository,
  });

  @override
  State<_ParcelaSelectionModal> createState() => _ParcelaSelectionModalState();
}

class _ParcelaSelectionModalState extends State<_ParcelaSelectionModal> {
  String? _selectedFinca;
  String? _selectedVariedad;
  String? _selectedParaje;
  String? _selectedAnoPlantacion;
  
  List<String> _fincas = [];
  List<String> _variedades = [];
  List<String> _parajes = [];
  List<String> _anos = [];
  int _parcelasCount = 0;
  
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadFincas();
  }
  
  Future<void> _loadFincas() async {
    try {
      final fincas = await widget.parcelaRepository.getFincas();
      setState(() {
        _fincas = fincas;
        _isLoading = false;
        // Si solo hay una finca, seleccionarla automáticamente
        if (_fincas.length == 1) {
          _selectedFinca = _fincas[0];
        }
      });
      // Cargar siguiente nivel o actualizar contador
      if (_selectedFinca != null) {
        await _loadVariedades();
      } else {
        _updateParcelasCount();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar fincas: $e')),
        );
      }
    }
  }
  
  Future<void> _loadVariedades() async {
    if (_selectedFinca == null) return;
    
    try {
      final todasParcelas = await widget.parcelaRepository.getParcelas();
      final variedadesSet = todasParcelas
          .where((p) => p.finca == _selectedFinca)
          .map((p) => p.variedad)
          .whereType<String>()
          .toSet();
      
      setState(() {
        _variedades = variedadesSet.toList()..sort();
        // Si solo hay una variedad, seleccionarla automáticamente
        if (_variedades.length == 1) {
          _selectedVariedad = _variedades[0];
          _loadParajes();
        }
      });
      _updateParcelasCount();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar variedades: $e')),
        );
      }
    }
  }
  
  Future<void> _loadParajes() async {
    if (_selectedFinca == null || _selectedVariedad == null) return;
    
    try {
      final todasParcelas = await widget.parcelaRepository.getParcelas();
      final parajesSet = todasParcelas
          .where((p) => 
            p.finca == _selectedFinca && 
            p.variedad == _selectedVariedad)
          .map((p) => p.paraje)
          .whereType<String>()
          .toSet();
      
      setState(() {
        _parajes = parajesSet.toList()..sort();
        // Si solo hay un paraje, seleccionarlo automáticamente
        if (_parajes.length == 1) {
          _selectedParaje = _parajes[0];
          _loadAnos();
        }
      });
      _updateParcelasCount();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar parajes: $e')),
        );
      }
    }
  }
  
  Future<void> _loadAnos() async {
    if (_selectedFinca == null || _selectedVariedad == null || _selectedParaje == null) return;
    
    try {
      final todasParcelas = await widget.parcelaRepository.getParcelas();
      final anosSet = todasParcelas
          .where((p) => 
            p.finca == _selectedFinca && 
            p.variedad == _selectedVariedad &&
            p.paraje == _selectedParaje)
          .map((p) => p.anoPlantacion)
          .whereType<String>()
          .toSet();
      
      setState(() {
        _anos = anosSet.toList()..sort();
        // Si solo hay un año, seleccionarlo automáticamente
        if (_anos.length == 1) {
          _selectedAnoPlantacion = _anos[0];
        }
      });
      _updateParcelasCount();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar años: $e')),
        );
      }
    }
  }
  
  Future<void> _updateParcelasCount() async {
    if (_selectedFinca == null) {
      setState(() {
        _parcelasCount = 0;
      });
      return;
    }
    
    try {
      final todasParcelas = await widget.parcelaRepository.getParcelas();
      final parcelasFiltradas = todasParcelas.where((parcela) {
        if (parcela.finca != _selectedFinca) return false;
        if (_selectedVariedad != null && parcela.variedad != _selectedVariedad) return false;
        if (_selectedParaje != null && parcela.paraje != _selectedParaje) return false;
        if (_selectedAnoPlantacion != null && parcela.anoPlantacion != _selectedAnoPlantacion) return false;
        return true;
      }).toList();
      
      setState(() {
        _parcelasCount = parcelasFiltradas.length;
      });
    } catch (e) {
      setState(() {
        _parcelasCount = 0;
      });
    }
  }
  
  void _handleAdd() async {
    await widget.onAdd(
      finca: _selectedFinca,
      variedad: _selectedVariedad,
      paraje: _selectedParaje,
      anoPlantacion: _selectedAnoPlantacion,
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Añadir Parcelas',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Selecciona los criterios. Puedes añadir en cualquier nivel de la jerarquía.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            
            // Contenido con scroll
            Expanded(
              child: SingleChildScrollView(
                child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Selector de Finca
                        if (_fincas.length > 1) ...[
                          const Text('Finca *', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedFinca,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            hint: const Text('Selecciona una finca'),
                            items: _fincas.map((finca) {
                              return DropdownMenuItem<String>(
                                value: finca,
                                child: Text(finca, overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedFinca = value;
                                _selectedVariedad = null;
                                _selectedParaje = null;
                                _selectedAnoPlantacion = null;
                                _variedades = [];
                                _parajes = [];
                                _anos = [];
                              });
                              if (value != null) {
                                _loadVariedades();
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                        ] else if (_fincas.length == 1) ...[
                          const Text('Finca *', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(_fincas[0], style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 16),
                        ],
                        
                        // Selector de Variedad
                        if (_selectedFinca != null && _variedades.length > 1) ...[
                          const Text('Variedad', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedVariedad,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            hint: const Text('Opcional: selecciona una variedad'),
                            items: _variedades.map((variedad) {
                              return DropdownMenuItem<String>(
                                value: variedad,
                                child: Text(variedad, overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedVariedad = value;
                                _selectedParaje = null;
                                _selectedAnoPlantacion = null;
                                _parajes = [];
                                _anos = [];
                              });
                              if (value != null) {
                                _loadParajes();
                              } else {
                                _updateParcelasCount();
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                        ] else if (_selectedFinca != null && _variedades.length == 1) ...[
                          const Text('Variedad', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(_variedades[0], style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 16),
                        ],
                        
                        // Selector de Paraje
                        if (_selectedVariedad != null && _parajes.length > 1) ...[
                          const Text('Paraje', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedParaje,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            hint: const Text('Opcional: selecciona un paraje'),
                            items: _parajes.map((paraje) {
                              return DropdownMenuItem<String>(
                                value: paraje,
                                child: Text(paraje, overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedParaje = value;
                                _selectedAnoPlantacion = null;
                                _anos = [];
                              });
                              if (value != null) {
                                _loadAnos();
                              } else {
                                _updateParcelasCount();
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                        ] else if (_selectedVariedad != null && _parajes.length == 1) ...[
                          const Text('Paraje', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(_parajes[0], style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 16),
                        ],
                        
                        // Selector de Año de Plantación
                        if (_selectedParaje != null && _anos.length > 1) ...[
                          const Text('Año de Plantación', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedAnoPlantacion,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            hint: const Text('Opcional: selecciona un año'),
                            items: _anos.map((ano) {
                              return DropdownMenuItem<String>(
                                value: ano,
                                child: Text(ano, overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedAnoPlantacion = value;
                              });
                              _updateParcelasCount();
                            },
                          ),
                          const SizedBox(height: 16),
                        ] else if (_selectedParaje != null && _anos.length == 1) ...[
                          const Text('Año de Plantación', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(_anos[0], style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Botón Añadir
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedFinca == null || _parcelasCount == 0 ? null : _handleAdd,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _parcelasCount > 0 ? 'Añadir ($_parcelasCount)' : 'Añadir',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
