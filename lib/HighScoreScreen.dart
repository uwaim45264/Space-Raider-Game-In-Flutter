import 'dart:math';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:confetti/confetti.dart';
import 'game_data_service.dart';
import 'package:audioplayers/audioplayers.dart';

class HighScoreScreen extends StatefulWidget {
  const HighScoreScreen({super.key});

  @override
  _HighScoreScreenState createState() => _HighScoreScreenState();
}

class _HighScoreScreenState extends State<HighScoreScreen> with TickerProviderStateMixin {
  int highScore = 0;
  String playerName = 'Unknown Player';
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late ConfettiController _confettiController;
  late AudioPlayer _audioPlayer;
  int _hoveredButton = -1;

  @override
  void initState() {
    super.initState();
    _loadHighScore();

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

    _confettiController = ConfettiController(duration: const Duration(seconds: 10));

    // Audio setup
    _audioPlayer = AudioPlayer();
    _playBackgroundMusic();
  }

  Future<void> _loadHighScore() async {
    final highScoreData = await GameDataService.getHighScore();
    setState(() {
      highScore = highScoreData['score'] ?? 0;
      playerName = highScoreData['name'] ?? 'Unknown Player';
      if (highScore > 0) {
        _confettiController.play();
      }
    });
  }

  Future<void> _playBackgroundMusic() async {
    try {
      print('Attempting to load audio: assets/audio/suspense-tension-background-music-323181.mp3');
      await _audioPlayer.setSource(AssetSource('audio/suspense-tension-background-music-323181.mp3'));
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.resume();
      print('Background music should be playing now');
    } catch (e) {
      print('Error playing background music: $e');
      try {
        await _audioPlayer.play(UrlSource('https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'));
        print('Playing fallback online test sound');
      } catch (fallbackError) {
        print('Fallback sound failed: $fallbackError');
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _confettiController.dispose();
    try {
      _audioPlayer.stop();
      _audioPlayer.dispose();
      print('Audio player stopped and disposed');
    } catch (e) {
      print('Error disposing audio: $e');
    }
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
                      const SizedBox(height: 80),
                      _buildTitle(),
                      const SizedBox(height: 50),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildHighScoreCard(),
                              const SizedBox(height: 40),
                              _buildBackButton(),
                              const SizedBox(height: 40),
                              _buildFooter(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: 3.14 / 2,
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            gravity: 0.1,
            colors: const [Colors.blue, Colors.white, Colors.lightBlueAccent],
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
            'HIGH SCORES',
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

  Widget _buildHighScoreCard() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Container(
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
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundImage: const AssetImage('assets/images/hacker.png'),
                  ),
                  const SizedBox(height: 16),
                  const FaIcon(
                    FontAwesomeIcons.trophy,
                    size: 50,
                    color: Colors.amber,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'High Score',
                    style: const TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$highScore',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.blueAccent.withOpacity(0.6),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'by $playerName',
                    style: const TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildStarRating(highScore),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStarRating(int score) {
    int starCount = (score / 100).floor().clamp(0, 5);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return Icon(
          index < starCount ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 32,
        );
      }),
    );
  }

  Widget _buildBackButton() {
    const index = 100;
    final isHovered = _hoveredButton == index;
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isHovered ? _pulseAnimation.value * 1.05 : _pulseAnimation.value,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: MouseRegion(
              onEnter: (_) => setState(() => _hoveredButton = index),
              onExit: (_) => setState(() => _hoveredButton = -1),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16), // Reduced from 20
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
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24, // Reduced from 28
                      ),
                      SizedBox(width: 8), // Reduced from 12
                      Text(
                        'BACK',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 18, // Reduced from 20
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