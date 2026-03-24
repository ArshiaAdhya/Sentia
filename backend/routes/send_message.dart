/// MAIN CHAT API
/// Handles full backend flow:
/// 1. Receives user message
/// 2. Calls AI service (reply + emotion)
/// 3. Calls streak & mood service
/// 4. Calls seed service (calculate seeds)
/// 5. Calls DB service (store everything)
/// 6. Returns final response to frontend