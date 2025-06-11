import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sapce_raider/particle.dart';
import 'package:sapce_raider/power_up.dart';
import 'enemy.dart';
import 'explosion.dart';

class GamePainter extends CustomPainter {
  final double playerX;
  final double playerY;
  final List<Offset> bullets;
  final List<Enemy> enemies;
  final List<PowerUp> powerUps;
  final bool shieldActive;
  final List<Explosion> explosions;
  final List<ParticleSystem> particleEffects;
  final Animation<double> pulseAnimation;
  final List<PowerUpText> powerUpTexts;
  final int multiBulletLevel; // New parameter

  GamePainter(
      this.playerX,
      this.playerY,
      this.bullets,
      this.enemies,
      this.powerUps,
      this.shieldActive,
      this.explosions,
      this.particleEffects,
      this.pulseAnimation,
      this.powerUpTexts,
      this.multiBulletLevel,
      );

  @override
  void paint(Canvas canvas, Size size) {
    final playerPaint = Paint()
      ..color = Colors.transparent
      ..style = PaintingStyle.fill;
    final playerOutline = Paint()
      ..color = Colors.transparent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(
      Offset(playerX * size.width, playerY * size.height),
      25,
      playerPaint,
    );
    canvas.drawCircle(
      Offset(playerX * size.width, playerY * size.height),
      25,
      playerOutline,
    );

    // Bullet colors based on multiBulletLevel
    final bulletColors = [
      Colors.yellow, // Level 0
      Colors.orange, // Level 1
      Colors.redAccent, // Level 2
      Colors.purpleAccent, // Level 3+
    ];
    final bulletPaint = Paint()
      ..color = bulletColors[multiBulletLevel.clamp(0, bulletColors.length - 1)];
    for (Offset bullet in bullets) {
      canvas.drawCircle(
        Offset(bullet.dx * size.width, bullet.dy * size.height),
        5,
        bulletPaint,
      );
    }

    for (Enemy enemy in enemies) {
      final enemyPaint = Paint()..color = enemy.color;
      final enemyOutline = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      if (enemy.shape == 0) {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(enemy.position.dx * size.width, enemy.position.dy * size.height),
            width: enemy.size * size.width,
            height: enemy.size * size.height,
          ),
          enemyPaint,
        );
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(enemy.position.dx * size.width, enemy.position.dy * size.height),
            width: enemy.size * size.width,
            height: enemy.size * size.height,
          ),
          enemyOutline,
        );
      } else if (enemy.shape == 1) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(enemy.position.dx * size.width, enemy.position.dy * size.height),
            width: enemy.size * size.width,
            height: enemy.size * size.height,
          ),
          enemyPaint,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(enemy.position.dx * size.width, enemy.position.dy * size.height),
            width: enemy.size * size.width,
            height: enemy.size * size.height,
          ),
          enemyOutline,
        );
      } else {
        canvas.drawCircle(
          Offset(enemy.position.dx * size.width, enemy.position.dy * size.height),
          enemy.size * size.width / 2,
          enemyPaint,
        );
        canvas.drawCircle(
          Offset(enemy.position.dx * size.width, enemy.position.dy * size.height),
          enemy.size * size.width / 2,
          enemyOutline,
        );
      }
    }

    for (PowerUp powerUp in powerUps) {
      late LinearGradient gradient;
      late Color glowColor;
      late Color innerGlowColor;
      late Path iconPath;

      switch (powerUp.type) {
        case PowerUpType.shield:
          gradient = const LinearGradient(
            colors: [Colors.cyanAccent, Colors.blueAccent, Colors.cyan],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
          glowColor = Colors.cyan.withOpacity(0.6);
          innerGlowColor = Colors.white.withOpacity(0.8);
          iconPath = _shieldIconPath();
          break;
        case PowerUpType.multiBullet:
          gradient = const LinearGradient(
            colors: [Colors.yellowAccent, Colors.orangeAccent, Colors.yellow],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
          glowColor = Colors.yellow.withOpacity(0.6);
          innerGlowColor = Colors.white.withOpacity(0.8);
          iconPath = _boltIconPath();
          break;
        case PowerUpType.speedBoost:
          gradient = const LinearGradient(
            colors: [Colors.purpleAccent, Colors.pinkAccent, Colors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
          glowColor = Colors.purple.withOpacity(0.6);
          innerGlowColor = Colors.white.withOpacity(0.8);
          iconPath = _speedIconPath();
          break;
        case PowerUpType.healthRestore:
          gradient = const LinearGradient(
            colors: [Colors.redAccent, Colors.pink, Colors.red],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
          glowColor = Colors.red.withOpacity(0.6);
          innerGlowColor = Colors.white.withOpacity(0.8);
          iconPath = _heartIconPath();
          break;
      }

      final center = Offset(powerUp.position.dx * size.width, powerUp.position.dy * size.height);
      final baseSize = 24.0 * pulseAnimation.value;
      final rect = Rect.fromCenter(center: center, width: baseSize, height: baseSize);

      final outerGlowPaint = Paint()
        ..color = glowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.inflate(6), const Radius.circular(6)),
        outerGlowPaint,
      );

      final powerUpPaint = Paint()..shader = gradient.createShader(rect);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        powerUpPaint,
      );

      final innerGlowPaint = Paint()
        ..color = innerGlowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      canvas.drawCircle(center, baseSize * 0.3, innerGlowPaint);

      final borderPaint = Paint()
        ..shader = LinearGradient(
          colors: [Colors.white.withOpacity(0.6), glowColor.withOpacity(0.4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        borderPaint,
      );

      final ringPaint = Paint()
        ..color = glowColor.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, baseSize * 1.3 * pulseAnimation.value, ringPaint);

      final iconPaint = Paint()
        ..color = Colors.white.withOpacity(0.9)
        ..style = PaintingStyle.fill;
      canvas.save();
      canvas.translate(center.dx - baseSize * 0.4, center.dy - baseSize * 0.4);
      canvas.scale(baseSize * 0.8 / 24, baseSize * 0.8 / 24);
      canvas.drawPath(iconPath, iconPaint);
      canvas.restore();
    }

    for (PowerUpText powerUpText in powerUpTexts) {
      powerUpText.draw(canvas, size);
    }

    if (shieldActive) {
      final shieldPaint = Paint()
        ..color = Colors.green.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5;
      canvas.drawCircle(
        Offset(playerX * size.width, playerY * size.height),
        60,
        shieldPaint,
      );
    }

    for (Explosion explosion in explosions) {
      explosion.draw(canvas, size);
    }

    for (ParticleSystem effect in particleEffects) {
      effect.draw(canvas, size);
    }
  }

  Path _shieldIconPath() {
    final path = Path();
    path.moveTo(12, 2);
    path.lineTo(18, 6);
    path.lineTo(18, 14);
    path.quadraticBezierTo(18, 20, 12, 22);
    path.quadraticBezierTo(6, 20, 6, 14);
    path.lineTo(6, 6);
    path.close();
    return path;
  }

  Path _boltIconPath() {
    final path = Path();
    path.moveTo(14, 2);
    path.lineTo(8, 12);
    path.lineTo(16, 12);
    path.lineTo(10, 22);
    path.close();
    return path;
  }

  Path _speedIconPath() {
    final path = Path();
    path.moveTo(4, 12);
    path.lineTo(16, 6);
    path.lineTo(16, 18);
    path.close();
    path.moveTo(16, 12);
    path.lineTo(20, 10);
    path.lineTo(20, 14);
    path.close();
    return path;
  }

  Path _heartIconPath() {
    final path = Path();
    path.moveTo(12, 6);
    path.quadraticBezierTo(8, 2, 4, 6);
    path.quadraticBezierTo(2, 10, 4, 14);
    path.quadraticBezierTo(6, 18, 12, 22);
    path.quadraticBezierTo(18, 18, 20, 14);
    path.quadraticBezierTo(22, 10, 20, 6);
    path.quadraticBezierTo(16, 2, 12, 6);
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ParticleSystem {
  final List<Particle> particles;
  bool isComplete;

  ParticleSystem(Offset position, Color color)
      : particles = List.generate(
    30,
        (index) => Particle(
      position: position,
      velocity: Offset(
        (Random().nextDouble() - 0.5) * 2,
        (Random().nextDouble() - 0.5) * 2,
      ),
      radius: Random().nextDouble() * 5 + 2,
      fadeRate: Random().nextDouble() * 0.02 + 0.01,
      color: color.withOpacity(1),
    ),
  ),
        isComplete = false;

  void update() {
    isComplete = particles.every((particle) => particle.opacity <= 0);
    for (var particle in particles) {
      particle.update();
    }
  }

  void draw(Canvas canvas, Size size) {
    for (var particle in particles) {
      particle.draw(canvas, size);
    }
  }
}

class PowerUpText {
  Offset position;
  String text;
  Color color;
  double opacity;
  double scale;
  double offsetY;
  bool isComplete;

  PowerUpText(this.position, this.text, this.color)
      : opacity = 1.0,
        scale = 1.0,
        offsetY = 0.0,
        isComplete = false;

  void update() {
    opacity -= 0.02;
    scale += 0.01;
    offsetY -= 1.5;
    if (opacity <= 0) isComplete = true;
  }

  void draw(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color.withOpacity(opacity),
          fontSize: 20 * scale,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(opacity * 0.7),
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    final textOffset = Offset(
      position.dx * size.width - textPainter.width / 2,
      position.dy * size.height - textPainter.height / 2 + offsetY,
    );
    textPainter.paint(canvas, textOffset);
  }
}