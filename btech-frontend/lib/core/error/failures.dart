abstract class Failure {
  final String message;
  final String? internalDetails;
  const Failure(this.message, {this.internalDetails});
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.internalDetails});
}

class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.internalDetails});
}

class NetworkFailure extends Failure {
  const NetworkFailure(
      {String message = 'Please check your internet connection',
      super.internalDetails})
      : super(message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.internalDetails});
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.internalDetails});
}
