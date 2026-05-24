import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(statusCode: 405, body: {'error': 'Method not allowed'});
  }

  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final email = body['email'] as String?;
    final password = body['password'] as String?;

    if (email == null || password == null) {
      return Response.json(statusCode: 400, body: {'error': 'Email and password are required'});
    }

    final supabase = context.read<SupabaseClient>();
    
    final res = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    return Response.json(body: {
      'user_id': res.user?.id,
      'token': res.session?.accessToken,
      'message': 'Login successful',
    },);
  } on AuthException catch (e) {
    return Response.json(statusCode: 400, body: {'error': e.message});
  } catch (e) {
    return Response.json(statusCode: 500, body: {'error': e.toString()});
  }
}
