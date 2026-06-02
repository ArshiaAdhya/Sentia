import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Method not allowed'},
    );
  }

  // Auth is stateless on backend right now; logout happens client-side
  // by clearing the saved token/user metadata.
  return Response.json(
    body: {'success': true, 'message': 'Logged out successfully'},
  );
}
