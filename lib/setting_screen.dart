import 'dart:math';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with TickerProviderStateMixin {
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
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      _buildTitle(),
                      const SizedBox(height: 50),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildButton(
                                context,
                                'How to Play',
                                Icons.gamepad,
                                Colors.blueAccent,
                                0,
                                '1. Move the player left and right to dodge enemies.\n'
                                    '2. Tap the screen to shoot bullets.\n'
                                    '3. Collect power-ups to gain special abilities.\n'
                                    '4. Survive as long as possible and score points by destroying enemies.',
                              ),
                              const SizedBox(height: 16),
                              _buildButton(
                                context,
                                'Features',
                                Icons.star,
                                Colors.blueAccent,
                                1,
                                '- Dynamic gameplay with enemies and power-ups.\n'
                                    '- Multiple power-ups for enhanced gameplay.\n'
                                    '- Beautiful graphics and animations.\n'
                                    '- Game over screen with restart and menu options.',
                              ),
                              const SizedBox(height: 16),
                              _buildButton(
                                context,
                                'Game Modes',
                                Icons.list,
                                Colors.blueAccent,
                                2,
                                '1. Survival Mode: Survive against endless waves of enemies.\n'
                                    '2. Time Attack: Destroy as many enemies as possible within a time limit.\n'
                                    '3. Challenge Mode: Complete specific tasks for rewards.',
                              ),
                              const SizedBox(height: 16),
                              _buildButton(
                                context,
                                'Support',
                                Icons.support_agent,
                                Colors.blueAccent,
                                3,
                                'For help and support, contact us at:\n'
                                    'Email: support@yourgame.com\n'
                                    'Visit our website: www.yourgame.com/support',
                              ),
                              const SizedBox(height: 16),
                              _buildButton(
                                context,
                                'Developer',
                                Icons.person,
                                Colors.blueAccent,
                                4,
                                'SOFTWARE ENGINEER\nMuhammad Uwaim Qureshi\nContact: unknownmuq@gmail.com',
                              ),
                              const SizedBox(height: 16),
                              _buildButton(
                                context,
                                'Game Controls',
                                Icons.control_camera,
                                Colors.blueAccent,
                                5,
                                'Use the joystick to navigate your character and buttons for actions.',
                              ),
                              const SizedBox(height: 16),
                              _buildButton(
                                context,
                                'Tips & Tricks',
                                Icons.lightbulb,
                                Colors.blueAccent,
                                6,
                                '1. Always look out for power-ups.\n'
                                    '2. Avoid enemy attacks and plan your movements.\n'
                                    '3. Practice makes perfect; keep playing to improve your skills.',
                              ),
                              const SizedBox(height: 40),
                              _buildFooter(),
                            ],
                          ),
                        ),
                      ),
                      _buildBackButton(context),
                      const SizedBox(height: 20),
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
            'SETTINGS',
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
      String content,
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
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => CustomDialog(
                      label: label,
                      icon: icon,
                      content: content,
                      pulseAnimation: _pulseAnimation,
                      onClose: () => Navigator.pop(context),
                    ),
                  );
                },
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

  Widget _buildBackButton(BuildContext context) {
    const index = 100; // Unique index for back button
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
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isHovered ? Colors.blueAccent : Colors.blueAccent.withOpacity(0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      if (isHovered)
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'BACK',
                        style: TextStyle(
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

class CustomDialog extends StatefulWidget {
  final String label;
  final IconData icon;
  final String content;
  final Animation<double> pulseAnimation;
  final VoidCallback onClose;

  const CustomDialog({
    super.key,
    required this.label,
    required this.icon,
    required this.content,
    required this.pulseAnimation,
    required this.onClose,
  });

  @override
  _CustomDialogState createState() => _CustomDialogState();
}

class _CustomDialogState extends State<CustomDialog> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  int _hoveredCloseButton = -1;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward();

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blueAccent.withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        widget.icon,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.label,
                          style: const TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1,
                            shadows: [
                              Shadow(
                                color: Colors.blueAccent,
                                blurRadius: 8,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.content,
                    style: const TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 16,
                      color: Colors.white70,
                      height: 1.5,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AnimatedBuilder(
                      animation: widget.pulseAnimation,
                      builder: (context, child) {
                        final isHovered = _hoveredCloseButton == 1;
                        return Transform.scale(
                          scale: isHovered ? widget.pulseAnimation.value * 1.05 : widget.pulseAnimation.value,
                          child: MouseRegion(
                            onEnter: (_) => setState(() => _hoveredCloseButton = 1),
                            onExit: (_) => setState(() => _hoveredCloseButton = -1),
                            child: GestureDetector(
                              onTap: widget.onClose,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isHovered ? Colors.blueAccent : Colors.blueAccent.withOpacity(0.5),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    if (isHovered)
                                      BoxShadow(
                                        color: Colors.blueAccent.withOpacity(0.4),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'CLOSE',
                                      style: TextStyle(
                                        fontFamily: 'Orbitron',
                                        fontSize: 16,
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
                        );
                      },
                    ),
                  ),
                ],
              ),
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