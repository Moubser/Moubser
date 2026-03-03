import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'di/locator.dart';
import 'services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'presentation/views/welcome_view.dart';
import 'presentation/views/home_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    await SupabaseService.init();
  } catch (e) {
    debugPrint('Supabase Init Error: $e');
  }

  setupLocator();

  runApp(const MoubserApp());
}

class MoubserApp extends StatelessWidget {
  const MoubserApp({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = locator<SupabaseService>();

    return MaterialApp(
      title: 'Moubser - مبصر',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: supabase.isLoggedIn ? const HomeView() : const WelcomeView(),
    );
  }
}
