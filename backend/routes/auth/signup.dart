/// SIGNUP API
/// Creates new user account
/// Stores user in database

import 'package:dart_frog/dart_frog.dart';

Response onRequest(RequestContext context) {
  return Response.json(
    body: {
      'message': 'Signup route placeholder',
    },
  );
}