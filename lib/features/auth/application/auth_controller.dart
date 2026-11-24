import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../vault/application/vault_controller.dart';
import '../data/auth_service.dart';

class AuthState {
  final bool isLoading;
  final String? email;
  final String? error;
  const AuthState({this.isLoading = false, this.email, this.error});
  bool get isLoggedIn => email != null;
  AuthState copyWith({bool? isLoading, String? email, String? error}) =>
      AuthState(
        isLoading: isLoading ?? this.isLoading,
        email: email ?? this.email,
        error: error,
      );
}

class AuthController extends Notifier<AuthState> {
  final _service = AuthService();

  @override
  AuthState build() => const AuthState();

  String _cleanError(Object e) {
    return e.toString().replaceFirst(RegExp(r'^(Client)?Exception:\s*'), '');
  }

  Future<void> register(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.register(email, password);
      state = AuthState(email: _service.email);
      await ref.read(vaultControllerProvider.notifier).pullFromServer();
    } catch (e) {
      state = AuthState(error: _cleanError(e));
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.login(email, password);
      state = AuthState(email: _service.email);
      await ref.read(vaultControllerProvider.notifier).pullFromServer();
    } catch (e) {
      state = AuthState(error: _cleanError(e));
    }
  }

  Future<void> logout() async {
    await _service.logout();
    state = const AuthState();
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
