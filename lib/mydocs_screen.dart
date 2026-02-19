import 'package:flutter/material.dart';

import 'app_menu.dart';
import 'mypayrolls_screen.dart';

class MyDocsPage extends StatelessWidget {
  const MyDocsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      'Contrato',
      'Manipulación de alimentos',
      'Nóminas',
      'Finiquitos',
    ];

    return Scaffold(
      drawer: buildAppDrawer(context),
      appBar: AppBar(
        title: const Text('Mis documentos'),
        leading: Builder(builder: (context) => IconButton(icon: const Icon(Icons.menu, color: Colors.black), onPressed: () => Scaffold.of(context).openDrawer())),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(12.0),
          itemCount: items.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final label = items[index];
            return ListTile(
              title: Text(label),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                if (label == 'Nóminas') {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyPayrollsPage()));
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opción "$label" aún no implementada.')));
              },
            );
          },
        ),
      ),
    );
  }
}
