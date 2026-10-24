import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_model.dart';
import '../services/game_service.dart';

final gameServiceProvider = Provider<GameService>((ref) {
  return GameService();
});

/// Filter options for type: 'all', 'game', 'loot', 'beta'
class TypeFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void setFilter(String filter) {
    state = filter;
  }
}

final selectedTypeFilterProvider =
    NotifierProvider<TypeFilterNotifier, String>(TypeFilterNotifier.new);

/// Search query string notifier
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }
}

final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

class GameNotifier extends AsyncNotifier<List<GameModel>> {
  @override
  FutureOr<List<GameModel>> build() {
    final service = ref.watch(gameServiceProvider);
    return service.fetchGames();
  }

  Future<void> refreshGames() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(gameServiceProvider);
      return service.fetchGames();
    });
  }
}

final gameNotifierProvider =
    AsyncNotifierProvider<GameNotifier, List<GameModel>>(GameNotifier.new);

/// Provides the filtered list based on search and type filter
final filteredGamesProvider = Provider<AsyncValue<List<GameModel>>>((ref) {
  final gamesAsync = ref.watch(gameNotifierProvider);
  final typeFilter = ref.watch(selectedTypeFilterProvider);
  final searchQuery = ref.watch(searchQueryProvider).trim().toLowerCase();

  return gamesAsync.whenData((games) {
    return games.where((game) {
      final matchesType = typeFilter == 'all' ||
          (typeFilter == 'game' &&
              game.type.toLowerCase().contains('game')) ||
          (typeFilter == 'loot' &&
              (game.type.toLowerCase().contains('dlc') ||
                  game.type.toLowerCase().contains('loot'))) ||
          (typeFilter == 'beta' && game.type.toLowerCase().contains('beta'));

      final matchesSearch = searchQuery.isEmpty ||
          game.title.toLowerCase().contains(searchQuery) ||
          game.platforms.toLowerCase().contains(searchQuery) ||
          game.description.toLowerCase().contains(searchQuery);

      return matchesType && matchesSearch;
    }).toList();
  });
});

/// Fetches full giveaway detail by ID
final gameDetailProvider =
    FutureProvider.autoDispose.family<GameModel, int>((ref, id) async {
  final service = ref.watch(gameServiceProvider);
  return service.getGameDetail(id);
});

/// Returns a list of similar games for the detail screen
final similarGamesProvider =
    Provider.autoDispose.family<List<GameModel>, GameModel>((ref, current) {
  final gamesAsync = ref.watch(gameNotifierProvider);
  return gamesAsync.maybeWhen(
    data: (games) {
      final others = games.where((g) => g.id != current.id).toList();

      final currentWords = current.title
          .toLowerCase()
          .split(RegExp(r'[\s:,()\-]+'))
          .where((w) =>
              w.length > 3 &&
              w != 'giveaway' &&
              w != 'steam' &&
              w != 'epic' &&
              w != 'free' &&
              w != 'pack' &&
              w != 'loot')
          .toSet();

      final sameBrand = others.where((g) {
        final titleWords = g.title.toLowerCase().split(RegExp(r'[\s:,()\-]+'));
        return titleWords.any((w) => currentWords.contains(w));
      }).toList();

      final sameCategory = others
          .where((g) =>
              g.type.toLowerCase() == current.type.toLowerCase() ||
              g.breadcrumbCategory == current.breadcrumbCategory)
          .toList();

      final combined = <GameModel>[...sameBrand, ...sameCategory];
      final seen = <int>{};
      final result = <GameModel>[];
      for (final g in combined) {
        if (!seen.contains(g.id)) {
          seen.add(g.id);
          result.add(g);
        }
        if (result.length >= 4) break;
      }
      return result;
    },
    orElse: () => [],
  );
});
