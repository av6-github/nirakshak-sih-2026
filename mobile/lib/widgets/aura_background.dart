import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme.dart';

class AuraBackground extends StatelessWidget {
  final Widget child;

  const AuraBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.baseBackground,
      child: Stack(
        children: [
          // Aura Glacier Mist Layer 1
          Positioned(
            top: -60,
            left: -40,
            right: -40,
            height: 380,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.2, -0.4),
                    radius: 1.2,
                    colors: [
                      AppTheme.auraCyan.withValues(alpha: 0.28),
                      AppTheme.auraMint.withValues(alpha: 0.22),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // Aura Glacier Mist Layer 2 (Bottom Indigo & Mint flow)
          Positioned(
            bottom: -80,
            left: -60,
            right: -60,
            height: 480,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppTheme.auraMint.withValues(alpha: 0.18),
                      AppTheme.auraIndigo.withValues(alpha: 0.25),
                      AppTheme.auraIndigo.withValues(alpha: 0.35),
                    ],
                    stops: const [0.0, 0.45, 0.8, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // Subtle overall overlay
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.3),
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.2),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Child content on top
          SafeArea(
            child: child,
          ),
        ],
      ),
    );
  }
}
