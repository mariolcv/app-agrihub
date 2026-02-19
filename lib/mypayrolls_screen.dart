import 'package:flutter/material.dart';

class MyPayrollsPage extends StatelessWidget {
  const MyPayrollsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      'Nómina Agosto 2025',
      'Nómina Julio 2025',
      'Nómina Junio 2025',
      'Nómina Mayo 2025',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis nóminas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Mostrar: $label'))),
            );
          },
        ),
      ),
    );
  }
}
