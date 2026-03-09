// lib/features/auth/bloc/auth_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/token_service.dart';

// ---- EVENTS ----
abstract class AuthEvent {}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  LoginRequested({required this.email, required this.password});
}

class BiometricLoginRequested extends AuthEvent {}
class LogoutRequested extends AuthEvent {}
class CheckAuthStatus extends AuthEvent {}

// ---- STATES ----
abstract class AuthState {}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final String email;
  Authenticated({required this.email});
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

// ---- BLOC ----
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  final TokenService _tokenService;

  AuthBloc({
    required AuthService authService,
    required TokenService tokenService,
  })  : _authService = authService,
        _tokenService = tokenService,
        super(AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LoginRequested>(_onLoginRequested);
    on<BiometricLoginRequested>(_onBiometricLogin);
    on<LogoutRequested>(_onLogoutRequested);
  }

  // App khulne par — token check karo
  Future<void> _onCheckAuthStatus(
      CheckAuthStatus event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());
    try {
      final token = await _tokenService.getAccessToken();
      if (token != null) {
        final user = await _authService.getCurrentUser();
        emit(Authenticated(email: user['email']));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(Unauthenticated());
    }
  }

  // Email/Password Login
  Future<void> _onLoginRequested(
      LoginRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());
    try {
      final user = await _authService.login(
        email: event.email,
        password: event.password,
      );
      emit(Authenticated(email: user['email']));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // Biometric Login
  Future<void> _onBiometricLogin(
      BiometricLoginRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());
    try {
      final isVerified = await _authService.verifyBiometric();
      if (isVerified) {
        final user = await _authService.getCurrentUser();
        emit(Authenticated(email: user['email']));
      } else {
        emit(AuthError('Biometric verification failed'));
      }
    } catch (e) {
      emit(AuthError('Biometric login failed'));
    }
  }

  // Logout
  Future<void> _onLogoutRequested(
      LogoutRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());
    try {
      await _authService.logout();
      emit(Unauthenticated());
    } catch (e) {
      await _tokenService.clearTokens();
      emit(Unauthenticated());
    }
  }
}