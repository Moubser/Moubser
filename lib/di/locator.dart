import 'package:get_it/get_it.dart';
import '../services/supabase_service.dart';
import '../services/tts_service.dart';
import '../services/gps_service.dart';
import '../services/stt_service.dart';
import '../services/ai_service.dart';
import '../services/chat_service.dart';
import '../services/navigation_service.dart';
import '../data/repositories/navigation_repository.dart';

final locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton(() => SupabaseService());
  locator.registerLazySingleton(() => TtsService());
  locator.registerLazySingleton(() => GpsService());
  locator.registerLazySingleton(() => SttService());
  locator.registerLazySingleton(() => AiService());
  locator.registerLazySingleton(() => ChatService());
  locator.registerLazySingleton(() => NavigationGraphService());
  locator.registerLazySingleton(() => NavigationRepository());
}
