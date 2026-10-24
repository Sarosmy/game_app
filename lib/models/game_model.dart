import 'dart:convert';
import 'package:flutter/material.dart';

List<GameModel> gameModelListFromJson(String str) =>
    List<GameModel>.from(json.decode(str).map((x) => GameModel.fromJson(x)));

String gameModelListToJson(List<GameModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

GameModel gameModelFromJson(String str) => GameModel.fromJson(json.decode(str));

String gameModelToJson(GameModel data) => json.encode(data.toJson());

String _unescapeHtml(String text) {
  return text
      .replaceAll('&#39;', "'")
      .replaceAll('&quot;', '"')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&nbsp;', ' ');
}

enum GameRarity {
  legendary,
  epic,
  rare,
  uncommon;

  String get label {
    switch (this) {
      case GameRarity.legendary:
        return 'LEGENDARY';
      case GameRarity.epic:
        return 'EPIC';
      case GameRarity.rare:
        return 'RARE';
      case GameRarity.uncommon:
        return 'UNCOMMON';
    }
  }

  Color get color {
    switch (this) {
      case GameRarity.legendary:
        return const Color(0xFFF59E0B); // Amber / Gold
      case GameRarity.epic:
        return const Color(0xFFA855F7); // Purple
      case GameRarity.rare:
        return const Color(0xFF38BDF8); // Sky Blue / Cyan
      case GameRarity.uncommon:
        return const Color(0xFF22C55E); // Green
    }
  }

  IconData get icon {
    switch (this) {
      case GameRarity.legendary:
        return Icons.emoji_events_outlined;
      case GameRarity.epic:
        return Icons.auto_awesome;
      case GameRarity.rare:
        return Icons.diamond_outlined;
      case GameRarity.uncommon:
        return Icons.inventory_2_outlined;
    }
  }
}

class GameModel {
  final int id;
  final String title;
  final String worth;
  final String thumbnail;
  final String image;
  final String description;
  final String instructions;
  final String openGiveawayUrl;
  final String publishedDate;
  final String type;
  final String platforms;
  final String endDate;
  final int users;
  final String status;
  final String gamerpowerUrl;

  const GameModel({
    required this.id,
    required this.title,
    required this.worth,
    required this.thumbnail,
    required this.image,
    required this.description,
    required this.instructions,
    required this.openGiveawayUrl,
    required this.publishedDate,
    required this.type,
    required this.platforms,
    required this.endDate,
    required this.users,
    required this.status,
    required this.gamerpowerUrl,
  });

  factory GameModel.fromJson(Map<String, dynamic> json) {
    final rawDesc = json['description']?.toString() ?? '';
    final rawInst = json['instructions']?.toString() ?? '';
    final rawTitle = json['title']?.toString() ?? '';

    final thumb = json['thumbnail']?.toString() ?? '';
    final img = json['image']?.toString() ?? '';

    return GameModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      title: _unescapeHtml(rawTitle),
      worth: json['worth']?.toString() ?? 'N/A',
      thumbnail: thumb.isNotEmpty ? thumb : img,
      image: img.isNotEmpty ? img : thumb,
      description: _unescapeHtml(rawDesc),
      instructions: _unescapeHtml(rawInst),
      openGiveawayUrl: json['open_giveaway_url']?.toString() ??
          json['open_giveaway']?.toString() ??
          '',
      publishedDate: json['published_date']?.toString() ?? '',
      type: json['type']?.toString() ?? 'Game',
      platforms: json['platforms']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? 'N/A',
      users: int.tryParse(json['users']?.toString() ?? '') ?? 0,
      status: json['status']?.toString() ?? 'Active',
      gamerpowerUrl: json['gamerpower_url']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'worth': worth,
        'thumbnail': thumbnail,
        'image': image,
        'description': description,
        'instructions': instructions,
        'open_giveaway_url': openGiveawayUrl,
        'published_date': publishedDate,
        'type': type,
        'platforms': platforms,
        'end_date': endDate,
        'users': users,
        'status': status,
        'gamerpower_url': gamerpowerUrl,
      };

  GameRarity get rarity {
    final tLower = type.toLowerCase();
    final isGame = tLower.contains('game');

    // DLC, in-game loot, and playtests are Uncommon
    if (!isGame) {
      return GameRarity.uncommon;
    }

    final cleanWorth = worth.replaceAll(RegExp(r'[^\d.]'), '').trim();
    final worthVal = double.tryParse(cleanWorth) ?? 0.0;
    final tName = title.toLowerCase();

    // Top tier legendary titles or large scale free full games
    if (tName.contains('agent a') || (isGame && worthVal >= 25.0) || (isGame && users >= 60000)) {
      return GameRarity.legendary;
    } else if (worthVal >= 15.0 && worthVal <= 24.0) {
      // E.g. Battle Ram ($20.00)
      return GameRarity.epic;
    } else if (worthVal > 1.0) {
      // E.g. Bad Cheese ($12.99), The Black Within ($5.99)
      return GameRarity.rare;
    }
    // E.g. Primal Slideee Deluxe ($1.00)
    return GameRarity.uncommon;
  }

  String get breadcrumbCategory {
    final t = type.toLowerCase();
    if (t.contains('beta') || t.contains('early')) {
      return 'Early Access';
    } else if (t.contains('game')) {
      return 'Game';
    }
    return 'In-Game Loot';
  }

  String get typeDisplayName {
    final t = type.toLowerCase();
    if (t.contains('beta') || t.contains('early')) {
      return 'Beta & Early Access';
    }
    if (t == 'dlc' || t.contains('loot')) {
      return 'DLC & Add-Ons';
    }
    if (t == 'game') {
      return 'Full Game';
    }
    return type;
  }

  String get similarHeading {
    if (breadcrumbCategory == 'Game') {
      return 'Similar free games';
    } else if (breadcrumbCategory == 'Early Access') {
      return 'Similar giveaways';
    }
    return 'Similar free loot';
  }

  List<String> get platformList {
    if (platforms.isEmpty) return [];
    return platforms
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
  }

  String get formattedDate {
    if (publishedDate.isEmpty) return '';
    try {
      final dt = DateTime.parse(publishedDate);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return 'Updated ${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return 'Updated $publishedDate';
    }
  }

  bool get hasOriginalWorth {
    final clean = worth.replaceAll(RegExp(r'[^\d.]'), '').trim();
    final val = double.tryParse(clean);
    return val != null && val > 0;
  }
}
