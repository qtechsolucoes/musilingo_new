// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:musilingo/app/core/result.dart';
import 'package:musilingo/app/core/theme/app_colors.dart';
import 'package:musilingo/app/presentation/view/splash_screen.dart';
import 'package:musilingo/app/presentation/view/login_screen.dart';
import 'package:musilingo/app/presentation/view/main_navigation_screen.dart';
import 'package:musilingo/app/services/sfx_service.dart';
import 'package:musilingo/app/services/user_session.dart';
import 'package:musilingo/app/core/service_registry.dart';
import 'package:musilingo/app/services/gamification_service.dart';
import 'package:musilingo/app/services/unified_midi_service.dart';
import 'package:musilingo/features/practice_solfege/services/audio_analysis_service.dart';
import 'package:musilingo/app/services/orientation_service.dart';
import 'package:musilingo/app/data/repositories/profile_repository.dart';
import 'package:musilingo/app/data/repositories/lesson_repository.dart';
import 'package:musilingo/app/data/repositories/practice_repository.dart';
import 'package:provider/provider.dart' as provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carrega as variáveis de ambiente do ficheiro .env
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    // Usa as variáveis carregadas de forma segura
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Inicializar ServiceRegistry
  final registryResult = await ServiceRegistry.initialize();
  switch (registryResult) {
    case Success():
      break; // Sucesso, continua
    case Failure(errorMessage: final error):
      debugPrint('❌ Falha ao inicializar ServiceRegistry: $error');
  }

  // Registrar serviços principais
  await _registerServices();

  // ✅ ESTA LINHA ESTÁ NO LUGAR PERFEITO!
  // Carrega os efeitos sonoros na inicialização
  await SfxService.instance.loadSounds();

  runApp(
    ProviderScope(
      child: provider.ChangeNotifierProvider(
        create: (context) => UserSession(),
        child: const MusilingoApp(),
      ),
    ),
  );
}

final supabase = Supabase.instance.client;

/// Registra todos os serviços no ServiceRegistry
Future<void> _registerServices() async {
  debugPrint('🔧 Registrando serviços no ServiceRegistry...');

  // Registrar serviços como lazy singletons
  ServiceRegistry.registerLazySingleton<GamificationService>(
    GamificationService.create,
  );

  ServiceRegistry.registerLazySingleton<UnifiedMidiService>(
    UnifiedMidiService.create,
  );

  ServiceRegistry.registerFactory<AudioAnalysisService>(
    AudioAnalysisService.create,
  );

  // Registrar OrientationService como singleton
  ServiceRegistry.registerSingleton<OrientationService>(
    OrientationService.instance,
  );

  // Registrar repositories
  ServiceRegistry.registerLazySingleton<ProfileRepository>(
    () => ProfileRepository(),
  );

  ServiceRegistry.registerLazySingleton<LessonRepository>(
    () => LessonRepository(),
  );

  ServiceRegistry.registerLazySingleton<PracticeRepository>(
    () => PracticeRepository(),
  );

  debugPrint('✅ Serviços e repositórios registrados com sucesso');
}

class MusilingoApp extends StatelessWidget {
  const MusilingoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Musilingo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        brightness: Brightness.dark,
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme.apply(
                bodyColor: AppColors.text,
                displayColor: AppColors.text,
              ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.accent,
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _checkInitialSession();
  }

  Future<void> _checkInitialSession() async {
    await Future.delayed(const Duration(seconds: 3)); // Splash timing

    if (!mounted) return;

    final session = supabase.auth.currentSession;
    final userSession = context.read<UserSession>();

    if (session != null) {
      await userSession.initializeSession();
    }

    setState(() {
      _initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const SplashScreen();
    }

    return provider.Consumer<UserSession>(
      builder: (context, userSession, child) {
        if (userSession.currentUser != null) {
          return const MainNavigationScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
