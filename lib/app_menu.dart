import 'package:flutter/material.dart';
import 'data.dart';
import 'myworkinghours_screen.dart';
import 'homePage.dart';
import 'login_screen.dart';
import 'mydocs_screen.dart';
import 'entranceNFC_screen.dart';
import 'editworkinghours_screen.dart';

final List<String> _allMenuOptions = [
  'Tareas',
  'Mis horas trabajadas',
  'Documentos',
  'Registrar llegada',
  'Editar horas entrada/salida',
];

List<String> menuOptionsForRole(String? role) {
  if (role == null) return _allMenuOptions;
  switch (role) {
    case 'agricultor':
      // all except 'Editar horas entrada/salida'
      return _allMenuOptions.where((o) => o != 'Editar horas entrada/salida').toList();
    case 'almacen':
      // all except 'Editar horas entrada/salida' and 'Tareas'
      return _allMenuOptions.where((o) => o != 'Editar horas entrada/salida' && o != 'Tareas').toList();
    case 'responsable_personal':
      // all except 'Tareas'
      return _allMenuOptions.where((o) => o != 'Tareas').toList();
    case 'empleado':
      // empleados no deben ver Tareas ni la edición manual de horas
      return _allMenuOptions.where((o) => o != 'Tareas' && o != 'Editar horas entrada/salida').toList();
    default:
      return _allMenuOptions;
  }
}

Widget buildAppDrawer(BuildContext context) {
  final items = menuOptionsForRole(currentUser?.rol);
  return Drawer(
    child: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.lightGreenAccent),
            child: Row(
              children: [
                CircleAvatar(radius: 36, backgroundColor: Colors.white70, child: Icon(currentUser != null ? Icons.person : Icons.person_off)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(currentUser?.nombre_usuario ?? 'Invitado', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(currentUser?.rol ?? '', style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                )
              ],
            ),
          ),
          ...items.map((opt) => ListTile(
            title: Text(opt),
            onTap: () {
              Navigator.of(context).pop();
              if (opt == 'Mis horas trabajadas') {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyWorkingHoursPage()));
                return;
              }
              if (opt == 'Tareas') {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => MyHomePage(title: 'Gestión parcelas app')));
                return;
              }
              if (opt == 'Documentos') {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyDocsPage()));
                return;
              }
              if (opt == 'Registrar llegada') {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EntranceNFCPage()));
                return;
              }
              if (opt == 'Editar horas entrada/salida') {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditWorkingHoursPage()));
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(opt)));
            },
          )),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar sesión'),
            onTap: () async {
              Navigator.of(context).pop();
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Cerrar sesión'),
                  content: const Text('¿Seguro que quieres cerrar sesión?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Aceptar', style: TextStyle(color: Colors.green)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                // Clear currentUser and navigate to login, removing previous routes
                currentUser = null;
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false);
                }
              }
            },
          ),
        ],
      ),
    ),
  );
}
