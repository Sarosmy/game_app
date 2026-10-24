import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/game_model.dart';

class GameService {
  List<GameModel>? _cachedGames;

  /// Loads exactly 50 games locally without any external network connection.
  Future<List<GameModel>> fetchGames({
    String? platform,
    String? type,
    String? sortBy,
  }) async {
    if (_cachedGames == null) {
      final jsonString = await rootBundle.loadString('assets/games.json');
      final rawList = json.decode(jsonString) as List;
      _cachedGames = rawList
          .take(50)
          .map((item) => GameModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    var list = List<GameModel>.from(_cachedGames!);

    if (platform != null && platform.isNotEmpty && platform != 'all') {
      final pLower = platform.toLowerCase();
      list = list
          .where((g) => g.platforms.toLowerCase().contains(pLower))
          .toList();
    }

    if (type != null && type.isNotEmpty && type != 'all') {
      final tLower = type.toLowerCase();
      list = list.where((g) {
        if (tLower == 'game') return g.type.toLowerCase().contains('game');
        if (tLower == 'loot') {
          return g.type.toLowerCase().contains('dlc') ||
              g.type.toLowerCase().contains('loot');
        }
        if (tLower == 'beta') return g.type.toLowerCase().contains('beta');
        return g.type.toLowerCase().contains(tLower);
      }).toList();
    }

    if (sortBy != null && sortBy.isNotEmpty) {
      if (sortBy == 'value') {
        list.sort((a, b) {
          final valA = double.tryParse(
                  a.worth.replaceAll(RegExp(r'[^\d.]'), '')) ??
              0.0;
          final valB = double.tryParse(
                  b.worth.replaceAll(RegExp(r'[^\d.]'), '')) ??
              0.0;
          return valB.compareTo(valA);
        });
      } else if (sortBy == 'popularity') {
        list.sort((a, b) => b.users.compareTo(a.users));
      } else if (sortBy == 'date') {
        list.sort((a, b) => b.publishedDate.compareTo(a.publishedDate));
      }
    }

    // Returns strictly 50 games maximum
    return list.take(50).toList();
  }

  /// Returns detail for a specific game by ID from the local 50 games
  Future<GameModel> getGameDetail(int id) async {
    final games = await fetchGames();
    return games.firstWhere(
      (g) => g.id == id,
      orElse: () => games.first,
    );
  }
}
