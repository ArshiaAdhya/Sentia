class SanitizedPayload {

  SanitizedPayload({
    required this.cleanText,
    required this.updatedDictionary,
  });
  final String cleanText;
  final Map<String, String> updatedDictionary;
}