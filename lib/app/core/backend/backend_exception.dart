/// A failure from the community backend. [message] is safe to show a person;
/// [code] is the server's stable machine code (for example `handle_taken`).
class BackendException implements Exception {
  const BackendException(this.code, this.message, {this.status});

  /// The backend is switched off in this build.
  const BackendException.disabled()
    : code = 'backend_disabled',
      message = 'Community features are not available yet.',
      status = null;

  /// No connection, a timeout, or an unreadable answer.
  const BackendException.network()
    : code = 'network',
      message = 'Could not reach the community service. Check your '
          'connection and try again.',
      status = null;

  final String code;
  final String message;
  final int? status;

  bool get isUnauthorized => status == 401 || code == 'unauthorized';

  @override
  String toString() => 'BackendException($code): $message';
}
