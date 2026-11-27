import '../../domain/entities/app_user.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.matricule,
    this.role = 'user',
    this.isSuspended = false,
  });
  final String id;
  final String name;
  final String email;
  final String? matricule;
  final String role;
  final bool isSuspended;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: (json['_id'] ?? json['id'] ?? '').toString(),
    name: json['name']?.toString() ?? 'Utilisateur',
    email: json['email']?.toString() ?? '',
    matricule: json['matricule']?.toString(),
    role: json['role']?.toString() ?? 'user',
    isSuspended: json['isSuspended'] == true,
  );

  AppUser toEntity() => AppUser(
    id: id,
    name: name,
    email: email,
    matricule: matricule,
    role: role,
    isSuspended: isSuspended,
  );
}
