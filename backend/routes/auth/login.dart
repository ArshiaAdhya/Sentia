/// LOGIN API
/// Authenticates user
/// Returns session/token

import 'package:dart_frog/dart_frog.dart';

Response onRequest(RequestContext context) {
  return Response.json(
    body: {
      'message': 'Login route placeholder',
    },
  );
}