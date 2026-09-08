/// Representasi hasil operasi repository dengan graceful error handling.
///
/// Sesuai `math-speed-game-error-handling-spec.md` §1.
sealed class RepoResult<T> {
  const RepoResult();
}

class RepoSuccess<T> extends RepoResult<T> {
  const RepoSuccess(this.value);
  final T value;
}

class RepoFailure<T> extends RepoResult<T> {
  const RepoFailure(this.reason, [this.exception]);
  final String reason;
  final Object? exception;

  @override
  String toString() =>
      'RepoFailure: $reason${exception != null ? ' ($exception)' : ''}';
}
