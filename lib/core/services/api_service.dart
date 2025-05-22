import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class ApiService {
  // Login
  static Future<http.Response> login(String email, String password) {
    return http.post(
      Uri.parse('$apiBaseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
  }

  // Register
  static Future<http.Response> register(Map<String, dynamic> data) {
    return http.post(
      Uri.parse('$apiBaseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
  }

  // Get Projects
  static Future<http.Response> getProjects(String token) {
    return http.get(
      Uri.parse('$apiBaseUrl/projetos'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  // Create Project
  static Future<http.Response> createProject(String token, Map<String, dynamic> data) async {
   
    final response = await http.post(
      Uri.parse('$apiBaseUrl/projetos'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
 
    return response;
  }

  // Update Project
  static Future<http.Response> updateProject(String token, int id, Map<String, dynamic> data) {
    return http.put(
      Uri.parse('$apiBaseUrl/projetos/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
  }

  // Delete Project
  static Future<http.Response> deleteProject(String token, int id) {
    return http.delete(
      Uri.parse('$apiBaseUrl/projetos/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  // Get Weather
  static Future<http.Response> getWeather(String token, String city) {
    return http.get(
      Uri.parse('$apiBaseUrl/weather?city=$city'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }
}

// Nenhuma alteração necessária. O token está sendo utilizado corretamente nas chamadas de API.
