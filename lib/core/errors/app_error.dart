enum AppErrorCategory { domain, validation, persistence, platform }

abstract class AppError implements Exception {
  const AppError(this.message, this.category);

  final String message;
  final AppErrorCategory category;

  @override
  String toString() => message;
}

class ValidationError extends AppError {
  const ValidationError(String message)
    : super(message, AppErrorCategory.validation);
}

class DomainError extends AppError {
  const DomainError(String message) : super(message, AppErrorCategory.domain);
}

class NotFoundError extends AppError {
  const NotFoundError(String message) : super(message, AppErrorCategory.domain);
}

class PersistenceError extends AppError {
  const PersistenceError(String message)
    : super(message, AppErrorCategory.persistence);
}

class PlatformError extends AppError {
  const PlatformError(String message)
    : super(message, AppErrorCategory.platform);
}
