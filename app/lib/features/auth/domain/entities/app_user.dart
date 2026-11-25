import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.matricule,
    this.role = 'user',
  });
  final String id;
  final String name;
  final String email;
  final String? matricule;
  final String role;

  @override
  List<Object?> get props => [id, name, email, matricule, role];
}
