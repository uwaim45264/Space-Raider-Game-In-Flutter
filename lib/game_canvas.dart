import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'enemy.dart';
import 'explosion.dart';
import 'game_painter.dart';
import 'game_setting.dart';
import 'power_up.dart';

class GameDataService {
  static const String _highScoreKey = 'high_score';

  static Future<void> saveHighScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    int highScore = prefs.getInt(_highScoreKey) ?? 0;
    if (score > highScore) {
      await prefs.setInt(_highScoreKey, score);
    }
  }

  static Future<int> getHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_highScoreKey) ?? 0;
  }
}

class GameCanvas extends StatefulWidget {
  final GameSettings settings;
  final bool isPaused;

  const GameCanvas({super.key, required this.settings, required this.isPaused});

  @override
  _GameCanvasState createState() => _GameCanvasState();
}

class _GameCanvasState extends State<GameCanvas> with SingleTickerProviderStateMixin {
  double playerX = 0.5;
  double playerY = 0.8;
  String? playerImagePath;
  double enemySpawnRate = 0.01;
  int comboStreak = 0;
  double comboMultiplier = 1.0;
  List<Offset> bullets = [];
  List<Enemy> enemies = [];
  List<PowerUp> powerUps = [];
  List<Explosion> explosions = [];
  List<ParticleSystem> particleEffects = [];
  List<PowerUpText> powerUpTexts = [];
  List<Widget> floatingScores = [];
  int score = 0;
  int lives = 3;
  int highScore = 0;
  bool gameOver = false;
  bool shieldActive = false;
  int multiBulletLevel = 0; // Changed from bool to int
  bool isBossLevel = false;
  late AnimationController _controller;
  late Animation<double> pulseAnimation;
  late Timer bulletTimer;
  late Timer enemySpawnTimer;
  Random random = Random();

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _loadPlayerImage();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..addListener(_updateGame)
      ..repeat();

    pulseAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _controller.forward();
      }
    });

    bulletTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!widget.isPaused && !gameOver) {
        setState(_fireBullet);
      }
    });

    enemySpawnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!widget.isPaused && !gameOver) {
        _adjustDifficulty();
        _checkForBossLevel();
      }
    });
  }

  Future<void> _loadHighScore() async {
    highScore = await GameDataService.getHighScore();
    setState(() {});
  }

  Future<void> _loadPlayerImage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      playerImagePath = prefs.getString('selectedPlayerImage') ?? 'assets/images/space-shuttle.png';
    });
  }

  void _fireBullet() {
    if (multiBulletLevel > 0) {
      int bulletCount;
      switch (multiBulletLevel) {
        case 1:
          bulletCount = 3;
          break;
        case 2:
          bulletCount = 5;
          break;
        default:
          bulletCount = 7; // Cap at 7 for level 3+
      }
      double spread = 0.04; // Spread between bullets
      for (int i = 0; i < bulletCount; i++) {
        double offsetX = (i - (bulletCount - 1) / 2) * spread;
        bullets.add(Offset(playerX + offsetX, playerY));
      }
    } else {
      bullets.add(Offset(playerX, playerY));
    }
  }

  void _updateGame() {
    if (!gameOver && !widget.isPaused) {
      setState(() {
        _updateBullets();
        _updateEnemies();
        _spawnNewEnemiesAndPowerUps();
        _updatePowerUps();
        _collectPowerUps();
        _handleCollisions();
        _updateExplosions();
        _updateParticleEffects();
        powerUpTexts.forEach((text) => text.update());
        powerUpTexts.removeWhere((text) => text.isComplete);
      });
    }
  }

  void _updateBullets() {
    bullets = bullets
        .map((bullet) => bullet.translate(0, -widget.settings.bulletSpeed / MediaQuery.of(context).size.height))
        .toList()
      ..removeWhere((bullet) => bullet.dy < 0);
  }

  void _updateEnemies() {
    enemies = enemies.map((enemy) {
      enemy.position = enemy.position.translate(0, enemy.speed / MediaQuery.of(context).size.height);
      return enemy;
    }).toList()
      ..removeWhere((enemy) => enemy.position.dy > 1);
  }

  void _adjustDifficulty() {
    if (score > 100) {
      enemySpawnRate = 0.02;
      widget.settings.difficulty += 0.1;
    } else if (score > 200) {
      enemySpawnRate = 0.03;
      widget.settings.difficulty += 0.1;
    }
  }

  void _spawnNewEnemiesAndPowerUps() {
    if (random.nextDouble() < enemySpawnRate) {
      enemies.add(_generateRandomEnemy());
    }
    if (random.nextDouble() < 0.005) {
      powerUps.add(PowerUp(Offset(random.nextDouble(), 0), PowerUpType.values[random.nextInt(4)]));
    }
  }

  Enemy _generateRandomEnemy() {
    final List<String> enemyImages = [
      'assets/images/asteroid (1).png',
      'assets/images/asteroid (2).png',
      'assets/images/asteroid (3).png',
      'assets/images/asteroid (4).png',
      'assets/images/bronze.png',
      'assets/images/meteorite.png',
      'assets/images/rock.png',
    ];
    return Enemy(
      position: Offset(random.nextDouble(), 0),
      speed: random.nextDouble() * widget.settings.difficulty + 0.5,
      size: random.nextDouble() * 0.05 + 0.02,
      shape: random.nextInt(3),
      color: Colors.primaries[random.nextInt(Colors.primaries.length)],
      image: enemyImages[random.nextInt(enemyImages.length)],
    );
  }

  void _updatePowerUps() {
    powerUps = powerUps
        .map((powerUp) {
      powerUp.position =
          powerUp.position.translate(0, widget.settings.difficulty * 2.0 / MediaQuery.of(context).size.height);
      return powerUp;
    })
        .toList()
      ..removeWhere((powerUp) => powerUp.position.dy > 1);
  }

  void _collectPowerUps() {
    powerUps.removeWhere((powerUp) {
      if ((powerUp.position - Offset(playerX, playerY)).distance < 0.05) {
        particleEffects.add(ParticleSystem(powerUp.position, Colors.greenAccent));
        _activatePowerUp(powerUp);
        HapticFeedback.lightImpact();
        Color textColor;
        String text;
        switch (powerUp.type) {
          case PowerUpType.shield:
            textColor = Colors.cyan;
            text = "Shield Up!";
            break;
          case PowerUpType.multiBullet:
            textColor = Colors.yellow;
            text = "Multi-Shot L$multiBulletLevel!";
            break;
          case PowerUpType.speedBoost:
            textColor = Colors.purple;
            text = "Speed Boost!";
            break;
          case PowerUpType.healthRestore:
            textColor = Colors.red;
            text = "Health Up!";
            break;
        }
        powerUpTexts.add(PowerUpText(powerUp.position, text, textColor));
        return true;
      }
      return false;
    });
  }

  void _activatePowerUp(PowerUp powerUp) {
    switch (powerUp.type) {
      case PowerUpType.shield:
        shieldActive = true;
        _startShieldTimer();
        break;
      case PowerUpType.multiBullet:
        multiBulletLevel++; // Increment level
        _startMultiBulletTimer();
        break;
      case PowerUpType.speedBoost:
        _boostPlayerSpeed();
        break;
      case PowerUpType.healthRestore:
        if (lives < 3) lives++;
        break;
    }
  }

  void _startShieldTimer() => Future.delayed(const Duration(seconds: 10), () => setState(() => shieldActive = false));

  void _startMultiBulletTimer() {
    Future.delayed(const Duration(seconds: 20), () {
      setState(() {
        if (multiBulletLevel > 0) multiBulletLevel--; // Decrease level after duration
      });
    });
  }

  void _boostPlayerSpeed() {
    widget.settings.playerSpeed += 0.05;
    Future.delayed(const Duration(seconds: 5), () {
      setState(() {
        widget.settings.playerSpeed = max(widget.settings.playerSpeed - 0.05, 0.02);
      });
    });
  }

  void _handleCollisions() {
    bullets.removeWhere((bullet) {
      for (var enemy in enemies) {
        if ((bullet - enemy.position).distance < 0.05) {
          _createExplosion(enemy);
          _addFloatingScore(enemy.position, (10 * comboMultiplier).round());
          comboStreak += 1;
          _updateComboMultiplier();
          enemies.remove(enemy);
          score += (10 * comboMultiplier).round();
          HapticFeedback.mediumImpact();
          return true;
        }
      }
      return false;
    });

    for (var enemy in enemies) {
      if (enemy.position.dy > 0.9 && (enemy.position.dx - playerX).abs() < 0.05) {
        if (shieldActive) {
          shieldActive = false;
        } else {
          comboStreak = 0;
          comboMultiplier = 1.0;
          lives--;
          if (lives <= 0) {
            gameOver = true;
            _showGameOverDialog();
          }
        }
        enemies.remove(enemy);
        break;
      }
    }
  }

  void _updateComboMultiplier() {
    if (comboStreak >= 5) comboMultiplier = 1.5;
    if (comboStreak >= 10) comboMultiplier = 2.0;
    if (comboStreak >= 15) comboMultiplier = 3.0;
  }

  void _createExplosion(Enemy enemy) {
    explosions.add(Explosion(enemy.position, enemy.color));
    particleEffects.add(ParticleSystem(enemy.position, Colors.orangeAccent));
  }

  void _addFloatingScore(Offset position, int points) {
    final floatingScore = Positioned(
      left: MediaQuery.of(context).size.width * position.dx,
      top: MediaQuery.of(context).size.height * position.dy,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOut,
        builder: (context, scale, child) {
          return Transform.translate(
            offset: Offset(0, -50 * scale),
            child: Transform.scale(
              scale: 1.0 + scale * 0.5,
              child: Opacity(
                opacity: (1.0 - scale).clamp(0.0, 1.0),
                child: Text(
                  '+$points',
                  style: TextStyle(
                    color: Colors.yellowAccent,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.7),
                        blurRadius: 4,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
    floatingScores.add(floatingScore);
    Future.delayed(const Duration(milliseconds: 800), () => setState(() => floatingScores.remove(floatingScore)));
  }

  void _updateExplosions() {
    explosions.forEach((explosion) => explosion.update());
    explosions.removeWhere((explosion) => explosion.isComplete);
  }

  void _updateParticleEffects() {
    particleEffects.forEach((effect) => effect.update());
    particleEffects.removeWhere((effect) => effect.isComplete);
  }

  void _checkForBossLevel() {
    if (score > 0 && score % 1000 == 0 && !isBossLevel) {
      isBossLevel = true;
    }
  }

  void _showGameOverDialog() async {
    await GameDataService.saveHighScore(score);
    highScore = await GameDataService.getHighScore();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.9),
                  Colors.redAccent.withOpacity(0.6),
                  Colors.blue.withOpacity(0.5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.redAccent.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Game Over",
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.8),
                        blurRadius: 10,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Score: $score",
                  style: const TextStyle(
                    fontSize: 26,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  "High Score: $highScore",
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.amberAccent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildDialogButton("Restart", Colors.green, () {
                      Navigator.pop(context);
                      setState(() => _resetGame());
                    }),
                    _buildDialogButton("Menu", Colors.redAccent.shade200, () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    }),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogButton(String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 5,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 20,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _resetGame() {
    score = 0;
    lives = 3;
    shieldActive = false;
    multiBulletLevel = 0; // Reset level
    gameOver = false;
    comboStreak = 0;
    comboMultiplier = 1.0;
    enemies.clear();
    bullets.clear();
    powerUps.clear();
    explosions.clear();
    particleEffects.clear();
    powerUpTexts.clear();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        if (!gameOver && !widget.isPaused) {
          setState(() {
            playerX += (details.delta.dx / MediaQuery.of(context).size.width) * widget.settings.playerSpeed * 20;
            playerX = playerX.clamp(0.05, 0.95);
          });
        }
      },
      child: Stack(
        children: [
          _buildAnimatedBackground(),
          CustomPaint(
            size: MediaQuery.of(context).size,
            painter: GamePainter(
              playerX,
              playerY,
              bullets,
              enemies,
              powerUps,
              shieldActive,
              explosions,
              particleEffects,
              pulseAnimation,
              powerUpTexts,
              multiBulletLevel, // Pass multiBulletLevel
            ),
          ),
          Positioned(
            left: MediaQuery.of(context).size.width * playerX - 50,
            top: MediaQuery.of(context).size.height * playerY - 126,
            child: _buildPlayer(),
          ),
          ..._buildEnemies(),
          if (shieldActive || multiBulletLevel > 0) Positioned(top: 80, left: 20, child: _buildPowerUpIndicator()),
          Positioned(top: 20, left: 20, child: _buildScoreAndLives()),
          Positioned(
            top: MediaQuery.of(context).size.height * playerY - 60,
            left: MediaQuery.of(context).size.width * playerX - 60,
            child: _buildHealthBar(),
          ),
          ...floatingScores,
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedContainer(
            duration: const Duration(seconds: 5),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.9),
                  Colors.deepPurple.withOpacity(0.7),
                  Colors.blueAccent.withOpacity(0.5),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Image.asset(
              'assets/images/pexels-photo-3114462.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              color: Colors.black.withOpacity(0.4),
              colorBlendMode: BlendMode.overlay,
            ),
          ),
        ),
        ...List.generate(20, (index) {
          return Positioned(
            left: random.nextDouble() * MediaQuery.of(context).size.width,
            top: random.nextDouble() * MediaQuery.of(context).size.height,
            child: AnimatedOpacity(
              opacity: random.nextBool() ? 0.8 : 0.4,
              duration: Duration(milliseconds: 1500 + random.nextInt(2000)),
              curve: Curves.easeInOut,
              child: Container(
                width: 2 + random.nextDouble() * 2,
                height: 2 + random.nextDouble() * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 5,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPlayer() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            shieldActive ? Colors.cyanAccent.withOpacity(0.5) : Colors.white.withOpacity(0.2),
            Colors.transparent,
          ],
          stops: const [0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: shieldActive ? Colors.cyanAccent.withOpacity(0.6) : Colors.white.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 5,
          ),
          BoxShadow(
            color: shieldActive ? Colors.cyanAccent.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 3.8, end: 0.0),
        duration: const Duration(seconds: 2),
        curve: Curves.easeInOutSine,
        builder: (context, angle, child) {
          return Transform.rotate(
            angle: angle * (shieldActive ? -1 : 1),
            child: Image.asset(
              playerImagePath ?? 'assets/images/space-shuttle.png',
              width: 100,
              height: 110,
              fit: BoxFit.cover,
              color: shieldActive ? Colors.cyanAccent.withOpacity(0.8) : null,
              colorBlendMode: BlendMode.modulate,
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildEnemies() {
    return enemies.map((enemy) {
      return Positioned(
        left: MediaQuery.of(context).size.width * enemy.position.dx - 50,
        top: MediaQuery.of(context).size.height * enemy.position.dy - 50,
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: enemy.color.withOpacity(0.4),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: TweenAnimationBuilder<double>(
            duration: const Duration(seconds: 3),
            tween: Tween<double>(begin: 1.0, end: 1.2),
            curve: Curves.easeInOut,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(seconds: 10),
                  tween: Tween<double>(begin: 0.0, end: 2 * pi),
                  builder: (context, rotation, child) {
                    return Transform.rotate(
                      angle: rotation,
                      child: Image.asset(
                        enemy.image,
                        width: 70,
                        height: 70,
                        fit: BoxFit.contain,
                        colorBlendMode: BlendMode.srcATop,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      );
    }).toList();
  }

  Widget _buildPowerUpIndicator() {
    return Row(
      children: [
        if (shieldActive) _buildPowerUpIcon(Icons.shield, Colors.cyanAccent),
        if (multiBulletLevel > 0) _buildPowerUpIcon(Icons.bolt, Colors.yellowAccent),
      ],
    );
  }

  Widget _buildPowerUpIcon(IconData icon, Color color) {
    return AnimatedScale(
      scale: 1.2,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withOpacity(0.2),
              color.withOpacity(0.6),
              color.withOpacity(0.9),
            ],
            stops: const [0.2, 0.7, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.7),
              blurRadius: 15,
              spreadRadius: 3,
            ),
          ],
          border: Border.all(color: color.withOpacity(0.5), width: 2),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildScoreAndLives() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.score, color: Colors.yellowAccent, size: 20),
          const SizedBox(width: 5),
          Text(
            'Score: $score',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black, blurRadius: 2)],
            ),
          ),
          const SizedBox(width: 20),
          const Icon(Icons.favorite, color: Colors.redAccent, size: 20),
          const SizedBox(width: 5),
          Text(
            'Lives: $lives',
            style: const TextStyle(
              color: Colors.redAccent,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black, blurRadius: 2)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthBar() {
    return Container(
      width: 120,
      height: 20,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 120 * (lives / 3),
            height: 20,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.greenAccent.withOpacity(0.8),
                  Colors.green.withOpacity(0.9),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Center(
            child: Text(
              '$lives/3',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black, blurRadius: 2)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    bulletTimer.cancel();
    enemySpawnTimer.cancel();
    _controller.dispose();
    super.dispose();
  }
}