sealed class AppError implements Exception {
  const AppError(this.message);

  final String message;

  @override
  String toString() => message;
}

class ValidationError extends AppError {
  const ValidationError(super.message);
}

class NotFoundError extends AppError {
  const NotFoundError(super.message);
}

class PersistenceError extends AppError {
  const PersistenceError(super.message);
}
