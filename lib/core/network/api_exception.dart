class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, List<String>> errors;

  const ApiException(
    this.message, {
    this.statusCode,
    this.errors = const {},
  });

  bool get isUnauthenticated => statusCode == 401;

  @override
  String toString() => message;
}
