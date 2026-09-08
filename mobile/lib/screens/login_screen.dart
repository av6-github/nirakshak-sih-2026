import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF090D16)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.verified_user_rounded,
                  size: 72,
                  color: AppTheme.accentCyan,
                ),
                const SizedBox(height: 16),
                Text(
                  'NIRIKSHAK AI',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'AI-Guided Legal Metrology & Citizen Trust Platform',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
                const SizedBox(height: 48),

                Text(
                  'SELECT USER ROLE',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),

                _RoleCard(
                  title: 'Citizen / Consumer',
                  subtitle: 'Scan products, check compliance & file complaints',
                  icon: Icons.person_outline_rounded,
                  isSelected: auth.role == UserRoleState.citizen,
                  onTap: () {
                    ref.read(authProvider.notifier).selectRole(UserRoleState.citizen);
                  },
                ),

                const SizedBox(height: 12),

                _RoleCard(
                  title: 'Enforcement Officer',
                  subtitle: 'Inspect products, review queue & verify evidence',
                  icon: Icons.badge_outlined,
                  isSelected: auth.role == UserRoleState.officer,
                  onTap: () {
                    ref.read(authProvider.notifier).selectRole(UserRoleState.officer);
                  },
                ),

                const SizedBox(height: 12),

                _RoleCard(
                  title: 'System Administrator',
                  subtitle: 'Manage legal metrology rules & system analytics',
                  icon: Icons.admin_panel_settings_outlined,
                  isSelected: auth.role == UserRoleState.admin,
                  onTap: () {
                    ref.read(authProvider.notifier).selectRole(UserRoleState.admin);
                  },
                ),

                const SizedBox(height: 36),

                ElevatedButton(
                  onPressed: () {
                    if (auth.role == UserRoleState.officer) {
                      context.go('/officer');
                    } else {
                      context.go('/home');
                    }
                  },
                  child: const Text('CONTINUE TO PLATFORM'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.cardDark : AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.accentCyan : const Color(0xFF334155),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppTheme.accentCyan : Colors.grey),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppTheme.accentCyan),
          ],
        ),
      ),
    );
  }
}
