class SanitizedPayload {
  final String cleanText;
  final Map<String, String> updatedDictionary;

  SanitizedPayload({
    required this.cleanText,
    required this.updatedDictionary,
  });
}