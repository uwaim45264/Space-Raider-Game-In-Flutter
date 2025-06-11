import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sapce_raider/setting_screen.dart';
import 'HighScoreScreen.dart';
import 'garage_screen.dart';
import 'loading_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  _MainMenuScreenState createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  int _hoveredButton = -1;

  @override
  void initState() {
    super.initState();
    // Fade animation for the screen
    _fadeController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..forward();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    // Pulse animation for buttons
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          _buildStarfield(),
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTitle(),
                      const SizedBox(height: 50),
                      _buildButton(
                        context,
                        'PLAY',
                        Icons.play_arrow,
                        Colors.blueAccent,
                        0,
                            () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoadingScreen()),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildButton(
                        context,
                        'SETTINGS',
                        Icons.settings,
                        Colors.blueAccent,
                        1,
                            () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SettingsScreen()),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildButton(
                        context,
                        'HIGH SCORE',
                        Icons.star,
                        Colors.blueAccent,
                        2,
                            () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const HighScoreScreen()),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildButton(
                        context,
                        'GARAGE',
                        Icons.airplanemode_active,
                        Colors.blueAccent,
                        3,
                            () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const GarageScreen()),
                        ),
                      ),
                      const SizedBox(height: 40),
                      _buildFooter(),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        image: DecorationImage(
          image: AssetImage('assets/images/image.png'),
          fit: BoxFit.cover,
          opacity: 0.6,
          colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
        ),
      ),
    );
  }

  Widget _buildStarfield() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return CustomPaint(
          painter: StarPainter(_pulseController.value),
          child: Container(),
        );
      },
    );
  }

  Widget _buildTitle() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Text(
            'SPACE RAIDERS',
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 44,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
              shadows: [
                Shadow(
                  color: Colors.blueAccent.withOpacity(0.6),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildButton(
      BuildContext context,
      String label,
      IconData icon,
      Color color,
      int index,
      VoidCallback onPressed,
      ) {
    final isHovered = _hoveredButton == index;
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isHovered ? _pulseAnimation.value * 1.05 : _pulseAnimation.value,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: MouseRegion(
              onEnter: (_) => setState(() => _hoveredButton = index),
              onExit: (_) => setState(() => _hoveredButton = -1),
              child: GestureDetector(
                onTap: onPressed,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isHovered ? color : color.withOpacity(0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      if (isHovered)
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        label,
                        style: const TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Text(
            '© 2025 Space Command',
            style: TextStyle(
              fontFamily: 'Orbitron',
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
        );
      },
    );
  }
}

class StarPainter extends CustomPainter {
  final double animationValue;

  StarPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final random = Random(42);
    for (int i = 0; i < 100; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final opacity = 0.5 + 0.3 * (sin(animationValue * 2 * pi + i) + 1) / 2;
      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), 1 + random.nextDouble() * 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}