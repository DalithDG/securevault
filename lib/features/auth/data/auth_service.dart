class AuthService {
  String? _token;
  String? _email;

  bool get isLoggedIn => _token != null;
  String? get email => _email;

  Future<void> register(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (email.isEmpty || password.length < 6) {
      throw Exception('Datos inválidos');
    }
    _email = email;
    _token = 'mock-token-$email';
  }

  Future<void> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Credenciales inválidas');
    }
    _email = email;
    _token = 'mock-token-$email';
  }

  Future<void> logout() async {
    _token = null;
    _email = null;
  }
}