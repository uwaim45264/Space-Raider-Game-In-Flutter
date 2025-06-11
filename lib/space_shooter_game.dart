import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'game_canvas.dart';
import 'game_setting.dart';

void main() {
  runApp(const SpaceShooterApp());
}

class SpaceShooterApp extends StatelessWidget {
  const SpaceShooterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const SpaceShooterGame(),
    );
  }
}

class SpaceShooterGame extends StatefulWidget {
  const SpaceShooterGame({super.key});

  @override
  _SpaceShooterGameState createState() => _SpaceShooterGameState();
}

class _SpaceShooterGameState extends State<SpaceShooterGame> with SingleTickerProviderStateMixin {
  late GameSettings _settings = GameSettings(5.0, 0.05, 1.0);
  bool isPaused = false;
  bool isMuted = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _audioPlayer = AudioPlayer();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      debugPrint('Initializing audio player');
      await _playBackgroundMusic();
      _audioPlayer.onPlayerStateChanged.listen((state) {
        debugPrint('Player state changed: $state');
      });
      // Log errors via onLog (optional debugging)
      _audioPlayer.onLog.listen((message) {
        debugPrint('Audio log: $message');
      });
    } catch (e) {
      debugPrint('Audio initialization error: $e');
    }
  }

  Future<void> _playBackgroundMusic() async {
    try {
      debugPrint('Attempting to play local audio');
      await _audioPlayer.setSource(AssetSource('audio/background_music.mp3'));
      await _audioPlayer.setVolume(isMuted ? 0.0 : 1.0);
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.resume();
      debugPrint('Local audio playing');
    } catch (e) {
      debugPrint('Local audio failed: $e');
      debugPrint('Falling back to online audio');
      try {
        await _audioPlayer.setSourceUrl('https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3');
        await _audioPlayer.setVolume(isMuted ? 0.0 : 1.0);
        await _audioPlayer.setReleaseMode(ReleaseMode.loop);
        await _audioPlayer.resume();
        debugPrint('Online audio playing');
      } catch (e) {
        debugPrint('Online audio failed: $e');
      }
    }
  }

  void _toggleMute() async {
    try {
      setState(() {
        isMuted = !isMuted;
        debugPrint('Mute toggled to: $isMuted');
      });
      await _audioPlayer.setVolume(isMuted ? 0.0 : 1.0);
    } catch (e) {
      debugPrint('Error toggling mute: $e');
    }
  }

  @override
  void dispose() {
    try {
      _audioPlayer.stop();
      _audioPlayer.dispose();
      debugPrint('Audio player disposed');
    } catch (e) {
      debugPrint('Error disposing audio: $e');
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.deepOrange.shade900.withOpacity(0.4),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildTitleBar(),
                      Expanded(
                        child: GameCanvas(settings: _settings, isPaused: isPaused),
                      ),
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
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.5,
          colors: [
            Colors.black.withOpacity(0.9),
            Colors.deepOrange.shade800.withOpacity(0.6),
          ],
        ),
      ),
      child: Stack(
        children: [
          Opacity(
            opacity: 0.7,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/image.png'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Colors.black38, BlendMode.overlay),
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: StarPainter(_controller.value),
                child: Container(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTitleBar() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Space Raiders',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                    color: Colors.white.withOpacity(0.9),
                    shadows: [
                      Shadow(
                        color: Colors.deepOrange.shade400.withOpacity(0.6),
                        blurRadius: 10,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 25),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.deepOrange.shade400.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          isPaused ? Icons.play_arrow : Icons.pause,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: () {
                          setState(() {
                            isPaused = !isPaused;
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          isMuted ? Icons.volume_off : Icons.volume_up,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: _toggleMute,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ],
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
    final random = Random();
    for (int i = 0; i < 80; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final opacity = 0.5 + 0.3 * (sin(animationValue * 2 * pi + i) + 1) / 2;
      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), 1 + random.nextDouble() * 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}