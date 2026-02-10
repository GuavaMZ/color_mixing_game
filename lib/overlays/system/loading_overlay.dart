import 'package:flutter/material.dart';
import 'dart:math';

class LoadingOverlay extends StatefulWidget {
  const LoadingOverlay({super.key});

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentTipIndex = 0;

  final List<String> _tips = [
    "💡 Mix colors carefully - you have limited drops!",
    "🎯 Perfect matches earn 3 stars and bonus coins",
    "🔥 Chain perfect matches for combo bonuses",
    "⚡ Time Attack mode rewards speed",
    "🌀 Chaos Lab has unpredictable random events",
    "🎨 White lightens colors, black darkens them",
    "⭐ Earn stars to unlock new game modes",
    "🎪 Use helpers wisely - they cost coins",
    "🔬 Each beaker skin is purely cosmetic",
    "💰 Save coins for hints on tough levels",
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Rotate tips every 3 seconds
    Future.delayed(const Duration(seconds: 3), _rotateTip);
  }

  void _rotateTip() {
    if (mounted) {
      setState(() {
        _currentTipIndex = (_currentTipIndex + 1) % _tips.length;
      });
      Future.delayed(const Duration(seconds: 3), _rotateTip);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0A0E27),
      child: Stack(
        children: [
          // Animated background
          ...List.generate(20, (index) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final offset = (_controller.value + index / 20) % 1.0;
                return Positioned(
                  left:
                      Random(index).nextDouble() *
                      MediaQuery.of(context).size.width,
                  top: offset * MediaQuery.of(context).size.height,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.cyan.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyan.withValues(alpha: 0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated beaker icon
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + sin(_controller.value * 2 * pi) * 0.1,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.cyan.withValues(alpha: 0.3),
                              Colors.purple.withValues(alpha: 0.3),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyan.withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.science_outlined,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // Loading text
                const Text(
                  'Loading...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 20),

                // Progress indicator
                SizedBox(
                  width: 200,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return LinearProgressIndicator(
                        value: null,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color.lerp(
                            Colors.cyan,
                            Colors.purple,
                            _controller.value,
                          )!,
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 60),

                // Tip section
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 20,
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.cyan.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      _tips[_currentTipIndex],
                      key: ValueKey(_currentTipIndex),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
