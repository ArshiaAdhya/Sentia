import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  test('SentiaApp can be constructed', () {
    const app = SentiaApp(initialRouteIsHome: false);
    expect(app.initialRouteIsHome, isFalse);
  });
}
