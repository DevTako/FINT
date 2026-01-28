import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

class ApiService {
  // Configuración del servidor remoto
  static const String baseUrl = 'http://127.0.0.1:3306/api'; // Servidor local
  
  // Headers comunes para todas las peticiones
  static Map<String, String> _getHeaders({String? token}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Manejo de excepciones HTTP
  static String _handleHttpError(int statusCode, String responseBody) {
    switch (statusCode) {
      case 400:
        return 'Solicitud incorrecta. Verifica los datos enviados.';
      case 401:
        return 'No autorizado. Inicia sesión nuevamente.';
      case 403:
        return 'Acceso denegado. No tienes permisos para esta acción.';
      case 404:
        return 'Recurso no encontrado. Verifica la URL del servidor.';
      case 500:
        return 'Error del servidor. Intenta más tarde.';
      case 502:
        return 'Servidor no disponible. Intenta más tarde.';
      case 503:
        return 'Servicio temporalmente no disponible.';
      default:
        return 'Error desconocido ($statusCode): $responseBody';
    }
  }

  // LOGIN - Autenticación de usuario
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email,
          'password': _hashPassword(password), // Hash simple para seguridad
        }),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'userId': data['user_id'],
          'token': data['token'],
          'message': 'Inicio de sesión exitoso'
        };
      } else {
        return {
          'success': false,
          'message': _handleHttpError(response.statusCode, response.body)
        };
      }
    } on SocketException {
      return {'success': false, 'message': 'Sin conexión a internet'};
    } on HttpException {
      return {'success': false, 'message': 'Error de conexión HTTP'};
    } catch (e) {
      return {'success': false, 'message': 'Error inesperado: ${e.toString()}'};
    }
  }

  // REGISTRO - Crear nuevo usuario
  static Future<Map<String, dynamic>> register(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: _getHeaders(),
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': _hashPassword(password),
        }),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'userId': data['user_id'],
          'token': data['token'],
          'message': 'Usuario creado exitosamente'
        };
      } else {
        return {
          'success': false,
          'message': _handleHttpError(response.statusCode, response.body)
        };
      }
    } on SocketException {
      return {'success': false, 'message': 'Sin conexión a internet'};
    } on HttpException {
      return {'success': false, 'message': 'Error de conexión HTTP'};
    } catch (e) {
      return {'success': false, 'message': 'Error inesperado: ${e.toString()}'};
    }
  }

  // GUARDAR DATOS FINANCIEROS
  static Future<Map<String, dynamic>> saveFinancialData({
    required String userId,
    required String token,
    required double balance,
    required double income,
    required double expenses,
    required List<Map<String, dynamic>> transactions,
    required List<Map<String, dynamic>> budgets,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/financial-data'),
        headers: _getHeaders(token: token),
        body: jsonEncode({
          'user_id': userId,
          'balance': balance,
          'income': income,
          'expenses': expenses,
          'transactions': transactions,
          'budgets': budgets,
          'updated_at': DateTime.now().toIso8601String(),
        }),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Datos financieros guardados exitosamente'
        };
      } else {
        return {
          'success': false,
          'message': _handleHttpError(response.statusCode, response.body)
        };
      }
    } on SocketException {
      return {'success': false, 'message': 'Sin conexión a internet'};
    } on HttpException {
      return {'success': false, 'message': 'Error de conexión HTTP'};
    } catch (e) {
      return {'success': false, 'message': 'Error inesperado: ${e.toString()}'};
    }
  }

  // OBTENER DATOS FINANCIEROS
  static Future<Map<String, dynamic>> getFinancialData(String userId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/financial-data/$userId'),
        headers: _getHeaders(token: token),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
          'message': 'Datos obtenidos exitosamente'
        };
      } else {
        return {
          'success': false,
          'message': _handleHttpError(response.statusCode, response.body)
        };
      }
    } on SocketException {
      return {'success': false, 'message': 'Sin conexión a internet'};
    } on HttpException {
      return {'success': false, 'message': 'Error de conexión HTTP'};
    } catch (e) {
      return {'success': false, 'message': 'Error inesperado: ${e.toString()}'};
    }
  }

  // GUARDAR TRANSACCIÓN INDIVIDUAL
  static Future<Map<String, dynamic>> saveTransaction({
    required String userId,
    required String token,
    required String description,
    required double amount,
    required String category,
    required String type, // 'income' o 'expense'
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/transactions'),
        headers: _getHeaders(token: token),
        body: jsonEncode({
          'user_id': userId,
          'description': description,
          'amount': amount,
          'category': category,
          'type': type,
          'date': DateTime.now().toIso8601String(),
        }),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Transacción guardada exitosamente'
        };
      } else {
        return {
          'success': false,
          'message': _handleHttpError(response.statusCode, response.body)
        };
      }
    } on SocketException {
      return {'success': false, 'message': 'Sin conexión a internet'};
    } on HttpException {
      return {'success': false, 'message': 'Error de conexión HTTP'};
    } catch (e) {
      return {'success': false, 'message': 'Error inesperado: ${e.toString()}'};
    }
  }

  // ACTUALIZAR PRESUPUESTO
  static Future<Map<String, dynamic>> updateBudget({
    required String userId,
    required String token,
    required String category,
    required double budget,
    required double spent,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/budgets'),
        headers: _getHeaders(token: token),
        body: jsonEncode({
          'user_id': userId,
          'category': category,
          'budget': budget,
          'spent': spent,
          'updated_at': DateTime.now().toIso8601String(),
        }),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Presupuesto actualizado exitosamente'
        };
      } else {
        return {
          'success': false,
          'message': _handleHttpError(response.statusCode, response.body)
        };
      }
    } on SocketException {
      return {'success': false, 'message': 'Sin conexión a internet'};
    } on HttpException {
      return {'success': false, 'message': 'Error de conexión HTTP'};
    } catch (e) {
      return {'success': false, 'message': 'Error inesperado: ${e.toString()}'};
    }
  }

  // Hash simple de contraseña (solo para demostración)
  static String _hashPassword(String password) {
    // NOTA: En producción usa bcrypt o argon2
    return password.split('').reversed.join(); // Simple reversión para demo
  }

  // Verificar conexión con el servidor
  static Future<bool> checkConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: _getHeaders(),
      ).timeout(Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
