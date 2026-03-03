import 'package:supabase/supabase.dart';
import 'lib/core/constants/app_constants.dart';

void main() async {
  final supabase = SupabaseClient(AppConstants.supabaseUrl, AppConstants.supabaseAnonKey);
  
  print('Creating test user...');
  try {
    final AuthResponse res = await supabase.auth.signUp(
      email: 'user@moubser.com',
      password: 'moubserpassword',
      data: {
        'full_name': 'Moubser User',
        'phone': '1234567890',
      },
    );
    
    if (res.user != null) {
      try {
        await supabase.from('users').insert({
          'id': res.user!.id,
          'full_name': 'Moubser User',
          'email': 'user@moubser.com',
          'phone': '1234567890',
        });
        print('User inserted into users table.');
      } catch (e) {
        print('User details table insert failed or already exists. $e');
      }
    }
    print('\nUser created successfully!');
    print('Email: user@moubser.com');
    print('Password: moubserpassword');
  } catch (e) {
    print('User might already exist or failed to create: $e');
    print('\nLog in with:');
    print('Email: user@moubser.com');
    print('Password: moubserpassword');
  }
}
