import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../models/game_model.dart';
import '../providers/game_provider.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  bool _showButton = false;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scroller = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroller.addListener(() {
      if (_scroller.position.pixels < 300) {
        if (_showButton) {
          setState(() {
            _showButton = false;
          });
        }
      } else {
        if (!_showButton) {
          setState(() {
            _showButton = true;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _scroller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'Search games or platforms...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  ref.read(searchQueryProvider.notifier).setQuery(val);
                },
              )
            : const Row(
                children: [
                  Icon(Icons.sports_esports, color: Color(0xFF3B82F6)),
                  SizedBox(width: 8),
                  Text(
                    'GamerPower',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  ref.read(searchQueryProvider.notifier).setQuery('');
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: _showButton ? _buildFloating() : null,
    );
  }

  Widget _buildFilterChips() {
    final activeFilter = ref.watch(selectedTypeFilterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filters = [
      {'key': 'all', 'label': 'All Giveaways'},
      {'key': 'game', 'label': 'Full Games'},
      {'key': 'loot', 'label': 'DLC & Loot'},
      {'key': 'beta', 'label': 'Betas & Keys'},
    ];

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = activeFilter == filter['key'];

          return ChoiceChip(
            label: Text(filter['label']!),
            selected: isSelected,
            selectedColor: const Color(0xFF2563EB),
            backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            labelStyle: TextStyle(
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : Colors.black87),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
            side: BorderSide(
              color: isSelected
                  ? const Color(0xFF2563EB)
                  : (isDark ? Colors.white10 : Colors.black12),
            ),
            onSelected: (selected) {
              if (selected) {
                ref
                    .read(selectedTypeFilterProvider.notifier)
                    .setFilter(filter['key']!);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    final gamesAsync = ref.watch(filteredGamesProvider);

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(gameNotifierProvider.notifier).refreshGames();
      },
      child: gamesAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.videogame_asset_off,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text(
                        'No giveaways found',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Try changing your filter or search query.',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref
                              .read(selectedTypeFilterProvider.notifier)
                              .setFilter('all');
                          ref
                              .read(searchQueryProvider.notifier)
                              .setQuery('');
                          _searchController.clear();
                        },
                        child: const Text('Reset Filters'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return _buildGridView(items);
        },
        error: (e, s) {
          debugPrint('Error: ${e.toString()}');
          debugPrint('StackTrace: ${s.toString()}');
          return Center(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off, size: 64, color: Colors.redAccent),
                    const SizedBox(height: 12),
                    const Text(
                      'Failed to load giveaways',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      e.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(gameNotifierProvider.notifier).refreshGames();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => _buildSkeleton(),
      ),
    );
  }

  Widget _buildFloating() {
    return FloatingActionButton(
      shape: const CircleBorder(),
      onPressed: () {
        _scroller.animateTo(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      },
      child: const Icon(Icons.arrow_upward),
    );
  }

  Widget _buildGridView(List<GameModel> items) {
    return GridView.builder(
      controller: _scroller,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildItem(item);
      },
    );
  }

  Widget _buildItem(GameModel item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        Navigator.of(context).pushNamed('/detail', arguments: item);
      },
      child: Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black12,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Game Image
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: item.thumbnail.isNotEmpty
                        ? item.thumbnail
                        : item.image,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: isDark ? Colors.white10 : Colors.black12,
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: isDark ? Colors.white10 : Colors.black12,
                      child: const Icon(Icons.videogame_asset, size: 36),
                    ),
                  ),

                  // Top gradient shadow for badges
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 40,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black87, Colors.transparent],
                        ),
                      ),
                    ),
                  ),

                  // 100% FREE badge
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white70, width: 0.8),
                      ),
                      child: const Text(
                        '100% FREE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Rarity indicator badge
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(4),
                        border:
                            Border.all(color: item.rarity.color, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(item.rarity.icon,
                              size: 9, color: item.rarity.color),
                          const SizedBox(width: 3),
                          Text(
                            item.rarity.label,
                            style: TextStyle(
                              color: item.rarity.color,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Game Details
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        height: 1.2,
                      ),
                    ),

                    // Platforms info
                    Text(
                      item.platforms.isNotEmpty
                          ? item.platforms
                          : 'PC / Consoles',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),

                    // Price & Type footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Original price strikethrough if available
                        Text(
                          item.worth != 'N/A' && item.worth.isNotEmpty
                              ? item.worth
                              : r'$0.00',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white54 : Colors.black45,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),

                        // Type chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.typeDisplayName,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Skeletonizer(
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        itemCount: 10,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.68,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemBuilder: (context, index) {
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: Container(
                    color: Colors.grey.shade400,
                  ),
                ),
                const Expanded(
                  flex: 4,
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text('Awesome Free Game Title Here',
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        Text('PC, Steam, Epic Games',
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(r'$19.99'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
