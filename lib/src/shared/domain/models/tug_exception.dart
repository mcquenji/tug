/// An actionable failure safe to display without response bodies or secrets.
class TugException implements Exception {
  const TugException(this.message, {this.status, this.uncertain = false});
  final String message;
  final int? status;

  /// The server may have accepted a mutation; rediscover before another attempt.
  final bool uncertain;
  @override
  String toString() => message;
}
