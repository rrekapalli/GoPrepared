/// Typed result of an HTTP call (success value or failure).
sealed class ApiResult<T> {
  const ApiResult();

  bool get isSuccess => this is ApiSuccess<T>;
  bool get isFailure => this is ApiFailure<T>;

  T? get valueOrNull => switch (this) {
        ApiSuccess<T>(:final value) => value,
        ApiFailure<T>() => null,
      };

  R when<R>({
    required R Function(T value) success,
    required R Function(ApiFailure<T> failure) failure,
  }) =>
      switch (this) {
        ApiSuccess<T>(:final value) => success(value),
        ApiFailure<T>() => failure(this as ApiFailure<T>),
      };
}

final class ApiSuccess<T> extends ApiResult<T> {
  const ApiSuccess(this.value);
  final T value;
}

final class ApiFailure<T> extends ApiResult<T> {
  const ApiFailure({
    required this.message,
    this.statusCode,
    this.cause,
  });

  final String message;
  final int? statusCode;
  final Object? cause;
}
