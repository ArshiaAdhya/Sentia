import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;
import 'package:backend/env/envied.dart'; // Import your Env class

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(statusCode: 405, body: {'error': 'Method not allowed'});
  }

  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final email = body['email'] as String?;
    final password = body['password'] as String?;
    final username = body['username'] as String?;

    if (email == null || password == null) {
      return Response.json(statusCode: 400, body: {'error': 'Email and password are required'});
    }

    final supabase = context.read<SupabaseClient>();
    
    // SECURED: Using environment variables instead of hardcoded strings
    final adminClient = SupabaseClient(
      Env.supabaseUrl,
      Env.supabaseServiceRoleKey, 
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );

    // 1. Create the user implicitly bypassing email confirmation queues
    final userRes = await adminClient.auth.admin.createUser(
      AdminUserAttributes(
        email: email,
        password: password,
        emailConfirm: true,
        userMetadata: username != null ? {'username': username} : null,
      ),
    );

    // 2. Perform a standard login to get their session token
    final res = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    return Response.json(body: {
      'user_id': res.user?.id,
      'token': res.session?.accessToken,
      'message': 'Signup successful',
    });
  } on AuthException catch (e) {
    return Response.json(statusCode: 400, body: {'error': e.message});
  } catch (e) {
    return Response.json(statusCode: 500, body: {'error': e.toString()});
  }
}