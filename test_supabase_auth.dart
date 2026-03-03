import 'package:http/http.dart' as http;
import 'dart:convert';
import 'lib/core/constants/app_constants.dart';

void main() async {
  final url = Uri.parse('${AppConstants.supabaseUrl}/auth/v1/signup');
  try {
    final response = await http.post(
      url,
      headers: {
        'apikey': AppConstants.supabaseAnonKey,
        'Authorization': 'Bearer ${AppConstants.supabaseAnonKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': 'test@moubser.com',
        'password': 'password123',
        'data': {
          'full_name': 'Test User',
          'phone': '1234567890',
        }
      }),
    );
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final resMap = jsonDecode(response.body);
      final userId = resMap['user']['id'];
      print('Sign up successful! User ID: $userId');
      
      // Try DB insert
      final dbUrl = Uri.parse('${AppConstants.supabaseUrl}/rest/v1/users');
      final dbResponse = await http.post(
        dbUrl,
        headers: {
          'apikey': AppConstants.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConstants.supabaseAnonKey}',
          'Content-Type': 'application/json',
          'Prefer': 'return=representation',
        },
        body: jsonEncode({
          'firstname': 'Test',
          'lastname': 'User',
          'email': 'test@moubser.com',
          'phone': '1234567890',
          'password': '***'
        }),
      );
      print('DB Status Code: ${dbResponse.statusCode}');
      print('DB Response Body: ${dbResponse.body}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
