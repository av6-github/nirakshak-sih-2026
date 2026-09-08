import 'package:flutter_riverpod/flutter_riverpod.dart';

enum UserRoleState { citizen, officer, admin }

class AuthState {
  final bool isAuthenticated;
  final String userId;
  final String userName;
  final UserRoleState role;

  AuthState({
    required this.isAuthenticated,
    required this.userId,
    required this.userName,
    required this.role,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? userId,
    String? userName,
    UserRoleState? role,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      role: role ?? this.role,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier()
      : super(AuthState(
          isAuthenticated: true,
          userId: '00000000-0000-0000-0000-000000000001',
          userName: 'Citizen Inspector',
          role: UserRoleState.citizen,
        ));

  void selectRole(UserRoleState newRole) {
    String name = 'Citizen User';
    if (newRole == UserRoleState.officer) name = 'Officer Sharma (Badge OFF-882)';
    if (newRole == UserRoleState.admin) name = 'System Administrator';

    state = state.copyWith(role: newRole, userName: name);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
