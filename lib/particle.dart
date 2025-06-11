import 'dart:math';
import 'package:flutter/material.dart';


class Particle {
  Offset position;
  Offset velocity;
  double radius;
  double opacity = 1;
  final double fadeRate;
  Color color;

  Particle({
    required this.position,
    required this.velocity,
    required this.radius,
    required this.fadeRate,
    required this.color,
  });

  void update() {
    position += velocity * 0.05;

    // Randomly change direction slightly for dynamic movement
    velocity += Offset((Random().nextDouble() - 0.5) * 0.1, (Random().nextDouble() - 0.5) * 0.1);

    opacity -= fadeRate;
    if (opacity < 0) opacity = 0;

    // Gradually change color to a lighter shade
    color = color.withOpacity(opacity);
  }

  void draw(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withOpacity(opacity);
    canvas.drawCircle(
      Offset(position.dx * size.width, position.dy * size.height),
      radius,
      paint,
    );
  }
}
