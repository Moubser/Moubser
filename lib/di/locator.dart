import 'package:get_it/get_it.dart';
import '../services/supabase_service.dart';

final locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton(() => SupabaseService());
}
