/// HELPERS
/// Common utility functions
/// (formatting, calculations, etc.)
///
/// toIst()        — converts a UTC DateTime to IST (UTC+5:30)
/// isSameIstDay() — checks if two timestamps fall on the same IST calendar day
/// toDateString() — formats a DateTime as YYYY-MM-DD for Supabase date columns

// Converts a UTC DateTime to IST (UTC+5:30).
DateTime toIst(DateTime utc) => utc.toUtc().add(const Duration(hours: 5, minutes: 30));

// Checks if two DateTimes fall on the same IST calendar day.
bool isSameIstDay(DateTime a, DateTime b) {
  final aIst = toIst(a);
  final bIst = toIst(b);
  return aIst.year == bIst.year &&
      aIst.month == bIst.month &&
      aIst.day == bIst.day;
}

// Formats a DateTime as YYYY-MM-DD string (date only, for Supabase date columns).
String toDateString(DateTime dt) =>
    '${dt.year.toString().padLeft(4, '0')}-'
    '${dt.month.toString().padLeft(2, '0')}-'
    '${dt.day.toString().padLeft(2, '0')}';