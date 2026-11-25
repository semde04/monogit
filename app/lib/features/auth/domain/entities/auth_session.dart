import 'package:equatable/equatable.dart';

import 'app_user.dart';

class AuthSession extends Equatable {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });
  final String accessToken;
  final String refreshToken;
  final AppUser user;

  @override
  List<Object?> get props => [accessToken, refreshToken, user];
}
