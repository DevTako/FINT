import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // URL base del backend Node.js. Usa 10.0.2.2 para emulador Android o IP/localhost
  static String baseUrl = 'http://localhost:3000/api';

  static Map<String, String> _headers({String? token}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // LOGIN
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: _headers(),
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 8));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'token': data['data']['token'],
          'user': data['data']['user'],
          'user_id': data['data']['user_id'],
        };
      }
      return {'success': false, 'message': data['message'] ?? 'Error de autenticación'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión con el servidor ($baseUrl)'};
    }
  }

  // REGISTRO
  static Future<Map<String, dynamic>> register(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: _headers(),
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 8));

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 && data['success'] == true) {
        return {
          'success': true,
          'token': data['data']['token'],
          'user': data['data']['user'],
        };
      }
      return {'success': false, 'message': data['message'] ?? 'Error al registrar usuario'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: ${e.toString()}'};
    }
  }

  // OBTENER DATOS FINANCIEROS
  static Future<Map<String, dynamic>> getFinancialData(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/financial-data'),
        headers: _headers(token: token),
      ).timeout(const Duration(seconds: 8));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': data['data']};
      }
      return {'success': false, 'message': data['message'] ?? 'Error al cargar datos'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: ${e.toString()}'};
    }
  }

  // NUEVA TRANSACCIÓN
  static Future<Map<String, dynamic>> addTransaction({
    required String token,
    required String description,
    required double amount,
    required String type,
    required String category,
    String? note,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/transaction'),
        headers: _headers(token: token),
        body: jsonEncode({
          'descripcion': description,
          'monto': amount,
          'tipo': type,
          'categoria': category,
          'nota': note ?? '',
        }),
      ).timeout(const Duration(seconds: 8));

      final data = jsonDecode(response.body);
      return {'success': response.statusCode == 200 && data['success'] == true, 'message': data['message']};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión'};
    }
  }

  // CREAR PRESUPUESTO
  static Future<Map<String, dynamic>> createBudget({
    required String token,
    required String category,
    required double limitAmount,
    required String period,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/budget'),
        headers: _headers(token: token),
        body: jsonEncode({
          'nombre': 'Presupuesto $category',
          'categoria': category,
          'monto_limite': limitAmount,
          'periodo': period,
        }),
      ).timeout(const Duration(seconds: 8));

      final data = jsonDecode(response.body);
      return {'success': response.statusCode == 200 && data['success'] == true, 'message': data['message']};
    } catch (e) {
      return {'success': false, 'message': 'Error al guardar presupuesto'};
    }
  }

  // TASAS DE CAMBIO EN VIVO (DIVISAS)
  static Future<Map<String, dynamic>> getExchangeRates(String baseCurrency) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/currency/rates?base=$baseCurrency'),
        headers: _headers(),
      ).timeout(const Duration(seconds: 8));

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return {'success': true, 'rates': data['rates'], 'source': data['source']};
      }
      return {'success': false, 'message': 'Error al cargar divisas'};
    } catch (e) {
      return {'success': false, 'message': 'Sin conexión a servicio de divisas'};
    }
  }

  // MERCADO VENEZUELA: BCV (Dólar Oficial) + Binance P2P (USDT y USDC)
  static Future<Map<String, dynamic>> getVenezuelaRates() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/currency/venezuela'),
        headers: _headers(),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': 'Error al obtener tasas de Venezuela'};
    } catch (e) {
      return {'success': false, 'message': 'Sin conexión con el servicio cambiario'};
    }
  }

  // CONVERSOR DE DIVISAS
  static Future<Map<String, dynamic>> convertCurrency({
    required double amount,
    required String from,
    required String to,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/currency/convert'),
        headers: _headers(),
        body: jsonEncode({'amount': amount, 'from': from, 'to': to}),
      ).timeout(const Duration(seconds: 8));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': data['data']};
      }
      return {'success': false, 'message': data['message'] ?? 'Error al convertir divisa'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: ${e.toString()}'};
    }
  }

  // ACTUALIZAR PERFIL
  static Future<Map<String, dynamic>> updateProfile({
    required String token,
    required String name,
    required String email,
    required String phone,
    required String housingZone,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/profile'),
        headers: _headers(token: token),
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'housingZone': housingZone,
        }),
      ).timeout(const Duration(seconds: 8));

      final data = jsonDecode(response.body);
      return {'success': response.statusCode == 200 && data['success'] == true, 'message': data['message']};
    } catch (e) {
      return {'success': false, 'message': 'Error al actualizar perfil'};
    }
  }

  // ELIMINAR CUENTA
  static Future<Map<String, dynamic>> deleteAccount(String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/profile'),
        headers: _headers(token: token),
      ).timeout(const Duration(seconds: 8));

      final data = jsonDecode(response.body);
      return {'success': response.statusCode == 200 && data['success'] == true, 'message': data['message']};
    } catch (e) {
      return {'success': false, 'message': 'Error al eliminar cuenta'};
    }
  }
}
