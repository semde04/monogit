import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  const Failure(this.message, {this.code});
  final String message;
  final String? code;

  @override
  List<Object?> get props => [message, code];
}

final class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'Connexion impossible. Vérifiez votre réseau.',
  ]);
}

final class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {this.fields = const {}, super.code});
  final Map<String, String> fields;

  @override
  List<Object?> get props => [...super.props, fields];
}

final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Une erreur inattendue est survenue.']);
}
