import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sapce_raider/particle.dart';

class Explosion {
  final List<Particle> particles;
  bool isComplete;
  double burstFactor;
  double shockwaveRadius;
  double shockwaveOpacity;
  double corePulse;
  double rippleFactor;
  double gravityFactor; // New: Gravitational pull
  double timeDilation; // New: Slow-motion effect

  Explosion(Offset position, Color explosionColor)
      : particles = List.generate(
    70, // Massive particle count
        (index) {
      double layer = index < 30 ? 0.05 : (index < 50 ? 0.1 : 0.15); // Multi-layered burst
      return Particle(
        position: position +
            Offset(
              (Random().nextDouble() - 0.5) * layer,
              (Random().nextDouble() - 0.5) * layer,
            ),
        velocity: Offset(
          (Random().nextDouble() - 0.5) * 6,
          (Random().nextDouble() - 0.5) * 6,
        ),
        radius: Random().nextDouble() * 12 + 6,
        fadeRate: Random().nextDouble() * 0.01 + 0.005,
        color: _getGradientColor(explosionColor, index),
      );
    },
  ),
        burstFactor = 1.0 + Random().nextDouble() * 1.0,
        shockwaveRadius = 0.0,
        shockwaveOpacity = 1.0,
        corePulse = 1.2,
        rippleFactor = 0.0,
        gravityFactor = 0.0, // Starts neutral, pulls later
        timeDilation = 0.0, // Starts normal speed
        isComplete = false;

  static Color _getGradientColor(Color baseColor, int index) {
    double t = index / 70;
    Color secondaryColor = _getComplementaryColor(baseColor);
    Color tertiaryColor = Colors.white.withOpacity(0.8); // Bright highlight
    return Color.lerp(
      Color.lerp(baseColor, secondaryColor, t)!,
      tertiaryColor,
      t * 0.3,
    )!.withOpacity((1.0 - t * 0.3).clamp(0.7, 1.0));
  }

  static Color _getComplementaryColor(Color color) {
    return Color.fromRGBO(
      255 - color.red,
      255 - color.green,
      255 - color.blue,
      1.0,
    );
  }

  void update() {
    isComplete = particles.every((particle) => particle.opacity <= 0) &&
        shockwaveOpacity <= 0 &&
        corePulse <= 0;
    timeDilation += 0.02; // Slows time effect
    gravityFactor += 0.01; // Increases pull over time
    for (var particle in particles) {
      // Apply gravitational pull toward center
      Offset center = particles[0].position;
      Offset direction = center - particle.position;
      double distance = direction.distance;
      if (distance > 0.01 && gravityFactor > 0.5) {
        particle.velocity += direction / distance * gravityFactor * 0.02;
      }
      particle.update();
      particle.radius *= 0.95; // Rapid decay
    }
    if (burstFactor > 1.0) burstFactor -= 0.08;
    shockwaveRadius += 3.0;
    shockwaveOpacity -= 0.015;
    if (shockwaveOpacity < 0) shockwaveOpacity = 0;
    corePulse -= 0.025;
    if (corePulse < 0) corePulse = 0;
    rippleFactor += 0.06;
    if (rippleFactor > 1.5) rippleFactor = 1.5;
  }

  void draw(Canvas canvas, Size size) {
    final Paint glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7.0);

    final Paint trailPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final Paint shockwavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..shader = RadialGradient(
        colors: [Colors.cyan, Colors.blue.withOpacity(0)],
        stops: [0.8, 1.0],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: shockwaveRadius));

    final Paint smokePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.grey.withOpacity(0.3);

    final Paint corePaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [Colors.yellow, Colors.orange, Colors.red, Colors.black.withOpacity(0)],
        stops: [0.0, 0.5, 0.8, 1.0],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: 25.0 * corePulse));

    final Paint emberPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.orange.withOpacity(0.5);

    final Paint flarePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withOpacity(0.4);

    // Center point for effects
    Offset center = Offset(
      particles[0].position.dx * size.width,
      particles[0].position.dy * size.height,
    );

    // Draw time-dilation ripple
    if (rippleFactor > 0) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.scale(1.0 + sin(rippleFactor * pi) * 0.08 * (1 - timeDilation.clamp(0, 1)));
      canvas.translate(-center.dx, -center.dy);
    }

    // Draw plasma shockwave
    if (shockwaveOpacity > 0) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.drawCircle(Offset.zero, shockwaveRadius, shockwavePaint);
      canvas.restore();
    }

    // Draw fiery core with embers
    if (corePulse > 0) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.drawCircle(Offset.zero, 25.0 * corePulse, corePaint);
      for (int i = 0; i < 5; i++) { // Glowing embers
        double angle = Random().nextDouble() * 2 * pi;
        double dist = Random().nextDouble() * 15 * corePulse;
        canvas.drawCircle(
          Offset(cos(angle) * dist, sin(angle) * dist),
          Random().nextDouble() * 3 + 1,
          emberPaint,
        );
      }
      canvas.restore();
    }

    for (var particle in particles) {
      Offset pos = Offset(particle.position.dx * size.width, particle.position.dy * size.height);

      // Draw smoke trail
      smokePaint.color = particle.color.withOpacity(particle.opacity * 0.2);
      for (int i = 1; i <= 5; i++) {
        double t = i / 5;
        Offset smokePos = particle.position - particle.velocity * t * 0.05;
        canvas.drawCircle(
          Offset(smokePos.dx * size.width, smokePos.dy * size.height),
          particle.radius * (2 - t),
          smokePaint,
        );
      }

      // Draw bright trail
      trailPaint.color = particle.color.withOpacity(particle.opacity * 0.6);
      for (int i = 1; i <= 8; i++) {
        double t = i / 8;
        Offset trailPos = particle.position - particle.velocity * t * 0.05;
        canvas.drawCircle(
          Offset(trailPos.dx * size.width, trailPos.dy * size.height),
          particle.radius * (1 - t),
          trailPaint,
        );
      }

      // Draw glow
      glowPaint.color = particle.color.withOpacity(particle.opacity * 0.9);
      canvas.drawCircle(pos, particle.radius * burstFactor * 2.5, glowPaint);

      // Draw rotating particle with flare
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(particle.opacity * pi * 3); // Faster, wilder spin
      final Paint sparklePaint = Paint()..color = particle.color.withOpacity(particle.opacity);
      canvas.drawPath(
        _starPath(particle.radius * 2), // Star-shaped particle
        sparklePaint,
      );
      if (Random().nextDouble() < 0.35) {
        canvas.drawCircle(Offset.zero, particle.radius * 2, flarePaint); // Bigger flare
      }
      canvas.restore();
    }

    if (rippleFactor > 0) canvas.restore(); // Close time-dilation layer
  }

  // Helper to create a star shape
  Path _starPath(double size) {
    final path = Path();
    const points = 5;
    double halfSize = size / 2;
    double innerSize = halfSize * 0.4;
    for (int i = 0; i < points * 2; i++) {
      double angle = i * pi / points;
      double radius = i.isEven ? halfSize : innerSize;
      double x = cos(angle) * radius;
      double y = sin(angle) * radius;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }
}