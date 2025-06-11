// game_data_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class GameDataService {
  static const String _highScoreKey = 'high_score';
  static const String _playerNameKey = 'player_name';
  static const String _scoreHistoryKey = 'score_history';

  // Save high score and player name if score is higher than current high score
  static Future<void> saveHighScore(int score, String playerName) async {
    final prefs = await SharedPreferences.getInstance();
    int highScore = prefs.getInt(_highScoreKey) ?? 0;

    // Load current score history
    List<int> scoreHistory = await getScoreHistory();

    if (score > highScore) {
      await prefs.setInt(_highScoreKey, score);
      await prefs.setString(_playerNameKey, playerName);

      // Add new score to history and save
      scoreHistory.add(score);
      await prefs.setString(_scoreHistoryKey, jsonEncode(scoreHistory));
    }
  }

  // Retrieve high score and player name
  static Future<Map<String, dynamic>> getHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    int highScore = prefs.getInt(_highScoreKey) ?? 0;
    String playerName = prefs.getString(_playerNameKey) ?? 'Unknown Player';

    return {
      'score': highScore,
      'name': playerName,
      'history': await getScoreHistory(),
    };
  }

  // Retrieve the score history
  static Future<List<int>> getScoreHistory() async {
    final prefs = await SharedPreferences.getInstance();
    String? scoreHistoryString = prefs.getString(_scoreHistoryKey);

    if (scoreHistoryString != null) {
      List<dynamic> jsonList = jsonDecode(scoreHistoryString);
      return jsonList.cast<int>();
    }
    return [];
  }
}
