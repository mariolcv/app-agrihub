import 'package:flutter/material.dart';

import 'app_menu.dart';

class EntranceNFCPage extends StatefulWidget {
  const EntranceNFCPage({super.key});

  @override
  State<EntranceNFCPage> createState() => _EntranceNFCPageState();
}

class _EntranceNFCPageState extends State<EntranceNFCPage> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _anim = Tween<double>(begin: 0.95, end: 1.12).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _ctrl.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _ctrl.forward();
      }
    });
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: buildAppDrawer(context),
      appBar: AppBar(
        title: const Text('Registrar entrada'),
        leading: Builder(builder: (context) => IconButton(icon: const Icon(Icons.menu, color: Colors.black), onPressed: () => Scaffold.of(context).openDrawer())),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.lightGreenAccent.withValues(alpha: 0.3)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _anim,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0,4))],
                    ),
                    child: const Center(
                      child: Icon(Icons.nfc, size: 96, color: Colors.lightGreen),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('acerca el móvil al lector', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 8),
                const Text('Se detectará automáticamente cuando el dispositivo esté cerca', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
