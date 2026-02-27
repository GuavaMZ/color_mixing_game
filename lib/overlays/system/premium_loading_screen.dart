import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../helpers/theme_constants.dart';
import '../../helpers/string_manager.dart';

/// A premium, full-screen loading overlay designed to be used during
/// the game's initial asset and data loading phase.
class PremiumLoadingScreen extends StatelessWidget {
  final ValueNotifier<double> progress;

  const PremiumLoadingScreen({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // Deep Blue to match splash
      body: Stack(
        children: [
          // Logo in the center
          Center(
            child: SvgPicture.asset(
              'assets/images/dv-logo.svg',
              width: 150,
              height: 150,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ),

          // Bottom alignment for progress bar
          Positioned(
            left: 40,
            right: 40,
            bottom: 60,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Loading Text with subtle letter spacing
                Text(
                  AppStrings.initializingLabArchives
                      .getString(context)
                      .toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    fontFamily: 'Roboto',
                  ),
                ),
                const SizedBox(height: 16),

                // Animated Progress Bar
                ValueListenableBuilder<double>(
                  valueListenable: progress,
                  builder: (context, value, child) {
                    return _PremiumProgressBar(value: value);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumProgressBar extends StatelessWidget {
  final double value;
  const _PremiumProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // The filled part of the bar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            width:
                (MediaQuery.of(context).size.width - 80) *
                value.clamp(0.0, 1.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: const LinearGradient(
                colors: [AppTheme.neonCyan, AppTheme.neonMagenta],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.neonCyan.withValues(alpha: 0.4),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
