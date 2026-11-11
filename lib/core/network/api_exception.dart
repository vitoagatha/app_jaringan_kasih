class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, List<String>> errors;
  final Duration? retryAfter;
  final String? code;

  const ApiException(
    this.message, {
    this.statusCode,
    this.errors = const {},
    this.retryAfter,
    this.code,
  });

  bool get isUnauthenticated => statusCode == 401;
  bool get isAccountDisabled => statusCode == 403 && code == 'account_disabled';
  String get displayMessage => statusCode == 429 &&
          retryAfter != null &&
          retryAfter!.inSeconds > 0
      ? '$message Tunggu sekitar ${retryAfter!.inSeconds} detik sebelum mencoba lagi.'
      : message;

  @override
  String toString() => message;
}
