import 'package:flutter/material.dart';
import 'package:gest_parcelas/data.dart';
import 'homePage.dart';
import 'services/auth_service.dart';
import 'services/empleado_service.dart';
import 'models/empleado_model.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _onLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa email y contraseña')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authService.login(email, password);
      
      // Convertir el UserModel a Usuario para compatibilidad con el código existente
      currentUser = Usuario(
        nombre_usuario: user.username,
        password: password,
        email: user.email,
        secret_code: '',
        rol: user.rol ?? 'empleado',
      );

      if (!mounted) return;

      // Navegar a la página principal (tareas de hoy)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MyHomePage(title: 'Gestión parcelas app')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al iniciar sesión: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Text('Bienvenido', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('¡Bienvenido! Listo para gestionar tus parcelas?', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 32),

              const Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'email@example.com',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),

              const Text('Contraseña', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Contraseña',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordPage())),
                  child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(color: Colors.orange)),
                ),
              ),

              const SizedBox(height: 8),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.lightGreenAccent, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                  onPressed: _isLoading ? null : _onLogin,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Iniciar sesión'),
                ),
              ),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("¿No tienes cuenta? "),
                  TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())), child: const Text('Registrarse', style: TextStyle(color: Colors.lightGreenAccent))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  final TextEditingController pass2Controller = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final AuthService _authService = AuthService();
  final EmpleadoService _empleadoService = EmpleadoService();
  
  bool _isLoading = false;
  bool _isLoadingEmpleados = true;
  List<EmpleadoModel> _empleados = [];
  EmpleadoModel? _selectedEmpleado;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEmpleados();
  }

  Future<void> _loadEmpleados() async {
    try {
      final empleados = await _empleadoService.getAllEmpleados();
      setState(() {
        _empleados = empleados;
        _isLoadingEmpleados = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar empleados: $e';
        _isLoadingEmpleados = false;
      });
    }
  }

  void _onRegister() async {
    if (_selectedEmpleado == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor selecciona tu nombre')));
      return;
    }

    if (codeController.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El código debe tener 6 dígitos')));
      return;
    }

    if (passController.text != pass2Controller.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Las contraseñas no coinciden')));
      return;
    }

    if (usernameController.text.trim().isEmpty || emailController.text.trim().isEmpty || passController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor completa todos los campos')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.register(
        username: usernameController.text.trim(),
        email: emailController.text.trim(),
        password: passController.text,
        confirmPassword: pass2Controller.text,
        empleadoId: _selectedEmpleado!.id,
        oneTimePassword: codeController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Cuenta activada exitosamente! Ya puedes iniciar sesión con tus credenciales'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      
      // Extraer el mensaje de error si es posible
      String errorMsg = e.toString();
      if (errorMsg.contains('Exception:')) {
        errorMsg = errorMsg.replaceAll('Exception:', '').trim();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Crear cuenta'), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(children: [
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 8),
            
            // Dropdown de empleados
            if (_isLoadingEmpleados)
              const CircularProgressIndicator()
            else
              DropdownButtonFormField<EmpleadoModel>(
                value: _selectedEmpleado,
                decoration: const InputDecoration(
                  labelText: 'Selecciona tu nombre',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                items: _empleados.map((empleado) {
                  return DropdownMenuItem<EmpleadoModel>(
                    value: empleado,
                    child: Text(empleado.nombre),
                  );
                }).toList(),
                onChanged: (EmpleadoModel? value) {
                  setState(() {
                    _selectedEmpleado = value;
                  });
                },
              ),
            
            const SizedBox(height: 12),
            
            // Código de registro
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Código de registro (6 dígitos)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
                hintText: '123456',
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            
            const SizedBox(height: 12),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Nombre de usuario',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_circle),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email de contacto',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Crear nueva contraseña',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pass2Controller,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Repetir nueva contraseña',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.lightGreenAccent, foregroundColor: Colors.black),
                onPressed: (_isLoading || _isLoadingEmpleados) ? null : _onRegister,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Registrarse'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController emailController = TextEditingController();

  void _onSend() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password recovery sent')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Recuperar contraseña'), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Text('Introduce tu email para recibir instrucciones'),
              const SizedBox(height: 12),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              SizedBox(height: 48, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.lightGreenAccent, foregroundColor: Colors.black), onPressed: _onSend, child: const Text('Enviar'))),
            ],
          ),
        ),
      ),
    );
  }
}
