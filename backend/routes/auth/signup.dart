import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;

Future<void> _ensureUserRow(SupabaseClient supabase, String userId) async {
  final existing =
      await supabase.from('users').select('id').eq('id', userId).maybeSingle();

  if (existing != null) return;

  await supabase.from('users').insert({
    'id': userId,
    'seeds': 50,
    'streak': 0,
  });
}

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Method not allowed'},
    );
  }

  try {
    final body = await context.request.json() as Map<String, dynamic>;

    final email = body['email'] as String?;
    final password = body['password'] as String?;
    final username = body['username'] as String?;

    if (email == null || password == null) {
      return Response.json(
        statusCode: 400,
        body: {'error': 'Email and password required'},
      );
    }

    final supabase = context.read<SupabaseClient>();

    final signUpRes = await supabase.auth.signUp(
      email: email,
      password: password,
      data: username != null ? {'username': username} : null,
    );

    User? user = signUpRes.user;
    Session? session = signUpRes.session;

    if (session == null) {
      try {
        final loginRes = await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
        user = loginRes.user ?? user;
        session = loginRes.session;
      } catch (_) {
        // If email verification is required, login can fail until verification.
      }
    }

    final userId = user?.id;

    if (userId != null) {
      try {
        await _ensureUserRow(supabase, userId);
      } catch (_) {
        // Keep signup resilient even if profile hydration fails due RLS.
      }
    }

    return Response.json(
      body: {
        'success': true,
        'user_id': userId,
        'token': session?.accessToken,
        'needs_email_verification': session == null,
        'message': session == null
            ? 'Signup successful. Verify your email, then login.'
            : 'Signup successful',
        'user': {
          'id': userId,
          'email': user?.email,
        },
        'session': {
          'access_token': session?.accessToken,
        },
      },
    );
  } on AuthException catch (e) {
    return Response.json(statusCode: 400, body: {'error': e.message});
  } catch (e) {
    return Response.json(statusCode: 500, body: {'error': e.toString()});
  }
}
