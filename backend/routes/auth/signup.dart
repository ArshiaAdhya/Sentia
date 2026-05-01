import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405, body: 'Method not allowed');
  }

  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final email = body['email'] as String?;
    final password = body['password'] as String?;

    if (email == null || password == null) {
      return Response.json(
        statusCode: 400,
        body: {'error': 'Email and password are required'},
      );
    }

    final supabase = context.read<SupabaseClient>();

    final AuthResponse res = await supabase.auth.signUp(
      email: email,
      password: password,
    );

    // After signup, we might want to ensure a user profile exists in the users table
    if (res.user != null) {
      try {
        await supabase.from('users').insert({
          'id': res.user!.id,
          'streak': 0,
          'seeds': 0,
        });
      } catch (e) {
        // If it fails (e.g. duplicate or missing table), we catch so the user still gets returned
        print('Error creating user profile: $e');
      }
    }

    return Response.json(
      body: {'user': res.user?.toJson(), 'session': res.session?.toJson()},
    );
  } catch (e) {
    return Response.json(statusCode: 400, body: {'error': e.toString()});
  }
}
