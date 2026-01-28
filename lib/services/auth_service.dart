import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://127.0.0.1:3306/api'; // Servidor local
  static String? _userId;
  static String? _token;

  // Guardar sesión localmente
  static Future<void> _saveSession(String userId, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
    await prefs.setString('token', token);
    _userId = userId;
    _token = token;
  }

  // Cargar sesión guardada
  static Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id');
    _token = prefs.getString('token');
  }

  // Cerrar sesión
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('token');
    _userId = null;
    _token = null;
  }

  // Verificar si está autenticado
  static bool get isAuthenticated => _userId != null && _token != null;
  static String? get userId => _userId;
  static String? get token => _token;

  // LOGIN
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': _hashPassword(password),
        }),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveSession(data['user_id'], data['token']);
        return {
          'success': true,
          'message': 'Inicio de sesión exitoso'
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Error en el login'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}'
      };
    }
  }

  // REGISTRO
  static Future<Map<String, dynamic>> register(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': _hashPassword(password),
        }),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await _saveSession(data['user_id'], data['token']);
        return {
          'success': true,
          'message': 'Usuario creado exitosamente'
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Error en el registro'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}'
      };
    }
  }

  // Hash simple de contraseña (solo para demostración)
  static String _hashPassword(String password) {
    // NOTA: En producción usa bcrypt o argon2
    return password.split('').reversed.join();
  }
}
