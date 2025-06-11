import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sapce_raider/space_shooter_game.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late AnimationController _orbitController;
  late AnimationController _textController;
  late AnimationController _scanController;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(duration: const Duration(seconds: 3), vsync: this);
    _pulseController = AnimationController(duration: const Duration(milliseconds: 2000), vsync: this)
      ..repeat(reverse: true);
    _orbitController = AnimationController(duration: const Duration(seconds: 3), vsync: this)..repeat();
    _textController = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this)
      ..repeat(reverse: true);
    _scanController = AnimationController(duration: const Duration(seconds: 4), vsync: this)..repeat();

    _progressController.forward().whenComplete(() {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SpaceShooterGame()));
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    _orbitController.dispose();
    _textController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Colors.grey.shade900],
          ),
        ),
        child: Stack(
          children: [
            AnimatedBackgroundGrid(
              pulseController: _pulseController,
              scanController: _scanController,
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SleekProgressIndicator(progressController: _progressController),
                  const SizedBox(height: 60),
                  PulsingRocketWithOrbit(pulseController: _pulseController, orbitController: _orbitController),
                  const SizedBox(height: 60),
                  AnimatedLoadingText(textController: _textController),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedBackgroundGrid extends StatelessWidget {
  final AnimationController pulseController;
  final AnimationController scanController;

  const AnimatedBackgroundGrid({
    required this.pulseController,
    required this.scanController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([pulseController, scanController]),
      builder: (context, child) {
        return CustomPaint(
          painter: GridPainter(pulseController.value, scanController.value),
          child: Container(),
        );
      },
    );
  }
}

class GridPainter extends CustomPainter {
  final double pulseValue;
  final double scanValue;

  GridPainter(this.pulseValue, this.scanValue);

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.orangeAccent.withOpacity(0.2 * pulseValue)
      ..strokeWidth = 0.7;

    // Grid lines
    for (int i = 0; i < 20; i++) {
      final y = size.height * (i / 20);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (int i = 0; i < 30; i++) {
      final x = size.width * (i / 30);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Scan line
    final scanPaint = Paint()
      ..color = Colors.redAccent.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);
    final scanY = size.height * scanValue;
    canvas.drawRect(Rect.fromLTWH(0, scanY - 20, size.width, 40), scanPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SleekProgressIndicator extends StatelessWidget {
  final AnimationController progressController;

  const SleekProgressIndicator({required this.progressController});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progressController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 260,
              height: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: Colors.grey.shade800.withOpacity(0.6),
              ),
            ),
            Container(
              width: 260,
              height: 12,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progressController.value,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation(Colors.orangeAccent.withOpacity(0.9)),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                final position = (index + 1) / 6;
                return Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: progressController.value >= position
                        ? Colors.redAccent
                        : Colors.grey.withOpacity(0.3),
                    boxShadow: [
                      if (progressController.value >= position)
                        BoxShadow(
                          color: Colors.redAccent.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                    ],
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}

class PulsingRocketWithOrbit extends StatelessWidget {
  final AnimationController pulseController;
  final AnimationController orbitController;

  const PulsingRocketWithOrbit({
    required this.pulseController,
    required this.orbitController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([pulseController, orbitController]),
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 100 + 10 * pulseController.value,
              height: 100 + 10 * pulseController.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.orangeAccent.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Transform.rotate(
                angle: orbitController.value * 2 * pi,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.redAccent,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent.withOpacity(0.5),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.redAccent.withOpacity(0.3 * pulseController.value),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Icon(
                Icons.rocket_launch,
                size: 70,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        );
      },
    );
  }
}

class AnimatedLoadingText extends StatelessWidget {
  final AnimationController textController;

  const AnimatedLoadingText({required this.textController});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: textController,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              Colors.orangeAccent.withOpacity(0.8 + 0.2 * textController.value),
              Colors.redAccent.withOpacity(0.8 + 0.2 * textController.value),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            'LOADING',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: 4.0,
              shadows: [
                Shadow(
                  color: Colors.redAccent.withOpacity(0.6 * textController.value),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
