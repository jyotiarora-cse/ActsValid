import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';

import 'core/theme/app_theme.dart';
import 'core/networks/dio_client.dart';
import 'core/services/token_service.dart';
import 'core/services/auth_service.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/presentation/splash_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/home/presentation/home_screen.dart';

// ✅ Yeh 2 imports add karo
import 'features/documents/bloc/document_bloc.dart';
import 'features/documents/data/document_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final tokenService = TokenService();
  final dioClient = DioClient(
    tokenService: tokenService,
    onLogout: () async {
      await tokenService.clearTokens();
    },
  );
  final authService = AuthService(
    dio: dioClient.dio,
    tokenService: tokenService,
  );

  // ✅ DioClient pass karo app mein
  runApp(ActsValidApp(
    authService: authService,
    tokenService: tokenService,
    dioClient: dioClient, // ✅ Naya
  ));
}

class ActsValidApp extends StatelessWidget {
  final AuthService authService;
  final TokenService tokenService;
  final DioClient dioClient; // ✅ Naya

  const ActsValidApp({
    super.key,
    required this.authService,
    required this.tokenService,
    required this.dioClient, // ✅ Naya
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider( // ✅ BlocProvider → MultiBlocProvider
      providers: [
        // AuthBloc
        BlocProvider(
          create: (context) => AuthBloc(
            authService: authService,
            tokenService: tokenService,
          ),
        ),
        // ✅ DocumentBloc add kiya
        BlocProvider(
          create: (context) => DocumentBloc(
            repository: DocumentRepository(
              dio: dioClient.dio,
            ),
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ActsValid',
        theme: AppTheme.lightTheme,
        home: const HomeScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
          '/splash': (context) => const SplashScreen(),
        },
      ),
    );
  }
}