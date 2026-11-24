import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../vault/data/vault_repository.dart';

class AuthService {
  final _vaultRepo = VaultRepository();
  String? _token;
  String? _email;

  bool get isLoggedIn => _token != null;
  String? get email => _email;

  Future<void> register(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw Exception('Ingresa un correo electrónico válido.');
    }
    if (password.length < 6) {
      throw Exception('La contraseña debe tener al menos 6 caracteres.');
    }

    final baseUrl = (await _vaultRepo.loadSyncUrl()).replaceAll(RegExp(r'/+$'), '');
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': cleanEmail, 'password': password}),
    );

    final data = _tryDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300 && data['ok'] == true) {
      _email = data['email']?.toString() ?? cleanEmail;
      _token = data['token']?.toString();
      return;
    }

    throw Exception(data['error']?.toString() ?? 'No se pudo registrar la cuenta (${res.statusCode}).');
  }

  Future<void> login(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty || password.isEmpty) {
      throw Exception('Ingresa correo y contraseña.');
    }

    final baseUrl = (await _vaultRepo.loadSyncUrl()).replaceAll(RegExp(r'/+$'), '');
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': cleanEmail, 'password': password}),
    );

    final data = _tryDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300 && data['ok'] == true) {
      _email = data['email']?.toString() ?? cleanEmail;
      _token = data['token']?.toString();
      return;
    }

    throw Exception(data['error']?.toString() ?? 'Credenciales inválidas (${res.statusCode}).');
  }

  Map<String, dynamic> _tryDecode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return const {};
  }

  Future<void> logout() async {
    _token = null;
    _email = null;
  }
}
