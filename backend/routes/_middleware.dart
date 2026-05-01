import 'package:backend/services/ai_service.dart';
import 'package:dart_frog/dart_frog.dart';

// 1. Create a single, persistent instance of the AI Service
final _aiService = AiService();

Handler middleware(Handler handler) {
  return handler.use(
    // 2. Inject it into the context so your routes can read it
    provider<AiService>((context) => _aiService),
  );
}