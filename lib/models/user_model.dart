import "package:logger/logger.dart";

class UserModel {
  static final _logger = Logger();
  
  final String? id;
  final String username;
  final String email;
  final String? rol;
  final String? avatar;
  final int? empleadoId;
  final EmpleadoBasic? empleado;

  UserModel({
    this.id,
    required this.username,
    required this.email,
    this.rol,
    this.avatar,
    this.empleadoId,
    this.empleado,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    _logger.d('UserModel.fromJson', error: json);
    
    // Backend devuelve: {id: "guest", name: "...", email: "...", role: "guest", avatar: "..."}
    final username = json['username'] ?? json['nombre_usuario'] ?? json['name'] ?? '';
    final email = json['email'] ?? '';
    final id = json['id']?.toString();
    
    _logger.i('Parseando usuario: $username ($email)');
    
    return UserModel(
      id: id,
      username: username,
      email: email,
      rol: json['rol'] ?? json['role'],
      avatar: json['avatar'],
      empleadoId: json['empleadoId'] ?? json['empleado_id'],
      empleado: json['empleado'] != null || json['empleados'] != null
          ? EmpleadoBasic.fromJson(json['empleado'] ?? json['empleados'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'rol': rol,
      'avatar': avatar,
      'empleadoId': empleadoId,
    };
  }
}

class EmpleadoBasic {
  static final _logger = Logger();
  
  final int id;
  final String nombre;
  final String? cargo;

  EmpleadoBasic({
    required this.id,
    required this.nombre,
    this.cargo,
  });

  factory EmpleadoBasic.fromJson(Map<String, dynamic> json) {
    _logger.d('EmpleadoBasic.fromJson', error: json);
    return EmpleadoBasic(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? json['name'] ?? '',
      cargo: json['cargo'] ?? json['position'],
    );
  }
}
