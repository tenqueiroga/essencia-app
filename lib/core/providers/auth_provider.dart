import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../network/api_client.dart';
import '../constants/api_constants.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final Map<String, dynamic>? user;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.user,
    this.error,
  });

  AuthState copyWith({bool? isAuthenticated, bool? isLoading, Map<String, dynamic>? user, String? error}) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _api = ApiClient();

  AuthNotifier() : super(const AuthState()) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final hasToken = await _api.hasToken();
      if (hasToken) {
        try {
          final response = await _api.dio.get(ApiConstants.userProfile);
          state = AuthState(
            isAuthenticated: true,
            isLoading: false,
            user: response.data is Map<String, dynamic> 
                ? response.data as Map<String, dynamic>
                : null,
          );
          return;
        } catch (_) {
          await _api.clearTokens();
        }
      }
    } catch (_) {}
    state = const AuthState(isAuthenticated: false, isLoading: false);
  }

  Future<void> loginWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      await _api.setTokens(
        response.data['access_token'],
        response.data['refresh_token'],
      );

      state = AuthState(
        isAuthenticated: true,
        isLoading: false,
        user: response.data['user'],
      );
    } catch (e) {
      String msg = 'Email ou senha incorretos.';
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  Future<void> register(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.dio.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
      });

      await _api.setTokens(
        response.data['access_token'],
        response.data['refresh_token'],
      );

      state = AuthState(
        isAuthenticated: true,
        isLoading: false,
        user: response.data['user'],
      );
    } catch (e) {
      String msg = 'Erro ao criar conta. Verifique os dados.';
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  Future<void> loginWithToken(String googleToken) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.dio.post(
        ApiConstants.authGoogleCallback,
        data: {'token': googleToken},
      );

      await _api.setTokens(
        response.data['access_token'],
        response.data['refresh_token'],
      );

      state = AuthState(
        isAuthenticated: true,
        isLoading: false,
        user: response.data['user'],
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Falha na autenticação. Tente novamente.',
      );
    }
  }

  Future<void> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      final account = await googleSignIn.signIn();
      if (account == null) {
        state = state.copyWith(isLoading: false);
        return; // User cancelled
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        state = state.copyWith(isLoading: false, error: 'Não foi possível obter token do Google.');
        return;
      }
      await loginWithToken(idToken);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Erro ao conectar com Google. Tente novamente.');
    }
  }

  Future<void> logout() async {
    try {
      await _api.dio.post(ApiConstants.authLogout);
    } catch (_) {}
    await _api.clearTokens();
    state = const AuthState(isAuthenticated: false, isLoading: false);
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _api.dio.patch(ApiConstants.userProfile, data: data);
      state = state.copyWith(user: response.data);
    } catch (_) {}
  }
}
