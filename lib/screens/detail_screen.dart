import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/game_model.dart';
import '../providers/game_provider.dart';

class DetailScreen extends ConsumerWidget {
  const DetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is GameModel) {
      return _DetailView(game: args);
    }

    final id = (args is int)
        ? args
        : int.tryParse(args?.toString() ?? '') ?? 0;

    final detailAsync = ref.watch(gameDetailProvider(id));

    return detailAsync.when(
      data: (game) => _DetailView(game: game),
      loading: () => Scaffold(
        backgroundColor: const Color(0xFF0D131F),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D131F),
          elevation: 0,
          leading: const BackButton(color: Colors.white),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
        ),
      ),
      error: (e, s) => Scaffold(
        backgroundColor: const Color(0xFF0D131F),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D131F),
          elevation: 0,
          leading: const BackButton(color: Colors.white),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                const SizedBox(height: 12),
                Text(
                  'Error loading game details:\n$e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(gameDetailProvider(id)),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailView extends ConsumerWidget {
  final GameModel game;
  const _DetailView({required this.game});

  Future<void> _launchUrl(BuildContext context, String url) async {
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null) {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link in browser.')),
        );
      }
    }
  }

  void _copyLink(BuildContext context, String url) {
    if (url.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: url));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link copied to clipboard!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _shareSocial(BuildContext context, String platform) {
    final link = game.openGiveawayUrl.isNotEmpty
        ? game.openGiveawayUrl
        : game.gamerpowerUrl;
    final text = 'Check out ${game.title} for free on GamerPower!';

    String shareUrl = '';
    switch (platform.toLowerCase()) {
      case 'google':
        shareUrl = 'https://www.google.com/search?q=${Uri.encodeComponent(game.title)}';
        break;
      case 'facebook':
        shareUrl =
            'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(link)}';
        break;
      case 'twitter':
        shareUrl =
            'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(text)}&url=${Uri.encodeComponent(link)}';
        break;
    }

    if (shareUrl.isNotEmpty) {
      _launchUrl(context, shareUrl);
    }
  }

  void _reportExpired(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF162032),
        title: const Row(
          children: [
            Icon(Icons.flag, color: Colors.orangeAccent),
            SizedBox(width: 8),
            Text('Report Expired', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          'Would you like to report "${game.title}" as expired?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Thank you! Report submitted.'),
                ),
              );
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF162032) : Colors.white;
    final pageBg = isDark ? const Color(0xFF0D131F) : const Color(0xFFF1F5F9);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black12;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final similarGames = ref.watch(similarGamesProvider(game));

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0D131F) : Colors.white,
        elevation: 0,
        leading: BackButton(color: textPrimary),
        title: Text(
          game.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: textPrimary),
            onPressed: () => _copyLink(
              context,
              game.openGiveawayUrl.isNotEmpty
                  ? game.openGiveawayUrl
                  : game.gamerpowerUrl,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ==================== TOP CARD (HEADER & INFO) ====================
            _buildCard(
              cardBg: cardBg,
              borderColor: borderColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Breadcrumb
                  _buildBreadcrumb(textSecondary),
                  const SizedBox(height: 12),

                  // Image + Rarity Badge below it
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: game.image.isNotEmpty ? game.image : game.thumbnail,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) => Container(
                        height: 200,
                        color: isDark ? Colors.white10 : Colors.black12,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 200,
                        color: isDark ? Colors.white10 : Colors.black12,
                        child: const Icon(Icons.broken_image, size: 48),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Rarity Box (Under image)
                  _buildRarityBadge(game.rarity),
                  const SizedBox(height: 14),

                  // Title of the game
                  Text(
                    game.title,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Platforms
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Text(
                        'For platforms:',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      ...game.platformList.map((platform) => _buildPlatformChip(platform, isDark)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Type
                  Row(
                    children: [
                      Text(
                        'Type: ',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        game.typeDisplayName,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Price & Worth row + Get Giveaway Button
                  Row(
                    children: [
                      // 100% FREE Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isDark ? Colors.white70 : Colors.black54,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '100% FREE',
                          style: TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Original Worth (with strikethrough)
                      Text(
                        game.worth != 'N/A' && game.worth.isNotEmpty ? game.worth : r'$0.00',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 14,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: textSecondary,
                        ),
                      ),
                      const Spacer(),

                      // Quick Claim Button
                      if (game.openGiveawayUrl.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: () => _launchUrl(context, game.openGiveawayUrl),
                          icon: const Icon(Icons.open_in_new, size: 14),
                          label: Text(
                            (game.breadcrumbCategory == 'In-Game Loot' ||
                                    game.type.toLowerCase().contains('dlc'))
                                ? 'Get Loot'
                                : 'Get Giveaway',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ==================== CARD 1: ABOUT THIS GIVEAWAY ====================
            _buildCard(
              cardBg: cardBg,
              borderColor: borderColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About this giveaway',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    game.description,
                    style: TextStyle(
                      color: textPrimary.withValues(alpha: 0.9),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  if (game.formattedDate.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      game.formattedDate,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(height: 1, thickness: 0.8),
                  const SizedBox(height: 14),

                  // Save & Share Buttons
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Text(
                        'Save & Share:',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      _buildSocialButton(
                        label: 'Google',
                        iconWidget: const FaIcon(
                          FontAwesomeIcons.google,
                          size: 11,
                        ),
                        isDark: isDark,
                        onTap: () => _shareSocial(context, 'google'),
                      ),
                      _buildSocialButton(
                        label: 'Facebook',
                        iconWidget: const FaIcon(
                          FontAwesomeIcons.facebookF,
                          size: 11,
                        ),
                        isDark: isDark,
                        onTap: () => _shareSocial(context, 'facebook'),
                      ),
                      _buildSocialButton(
                        label: 'Twitter',
                        iconWidget: const FaIcon(
                          FontAwesomeIcons.xTwitter,
                          size: 11,
                        ),
                        isDark: isDark,
                        onTap: () => _shareSocial(context, 'twitter'),
                      ),
                      _buildSocialButton(
                        label: 'Copy Link',
                        iconWidget: const FaIcon(
                          FontAwesomeIcons.link,
                          size: 11,
                        ),
                        isDark: isDark,
                        onTap: () => _copyLink(
                          context,
                          game.openGiveawayUrl.isNotEmpty
                              ? game.openGiveawayUrl
                              : game.gamerpowerUrl,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ==================== CARD 2: HOW TO CLAIM ====================
            _buildCard(
              cardBg: cardBg,
              borderColor: borderColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How to claim',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (game.instructions.isNotEmpty)
                    Text(
                      game.instructions,
                      style: TextStyle(
                        color: textPrimary.withValues(alpha: 0.9),
                        fontSize: 14,
                        height: 1.6,
                      ),
                    )
                  else
                    Text(
                      '1. Click the "Get Giveaway" button to visit the giveaway page.\n'
                      '2. Follow instructions on the destination website.\n'
                      '3. Claim and redeem your key or game.',
                      style: TextStyle(
                        color: textPrimary.withValues(alpha: 0.9),
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  const SizedBox(height: 18),

                  // Report Expired Button
                  OutlinedButton.icon(
                    onPressed: () => _reportExpired(context),
                    icon: const Icon(Icons.flag_outlined, size: 14),
                    label: const Text('Report expired'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textSecondary,
                      side: BorderSide(
                        color: isDark ? Colors.white24 : Colors.black26,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ==================== CARD 3: SIMILAR FREE LOOT / GAMES ====================
            _buildCard(
              cardBg: cardBg,
              borderColor: borderColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.similarHeading,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (similarGames.isEmpty)
                    Text(
                      'No similar items found currently.',
                      style: TextStyle(color: textSecondary, fontSize: 13),
                    )
                  else
                    ...similarGames.map((similar) {
                      return InkWell(
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            '/detail',
                            arguments: similar,
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '- ',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  similar.title,
                                  style: TextStyle(
                                    color: isDark
                                        ? const Color(0xFF93C5FD)
                                        : const Color(0xFF1D4ED8),
                                    fontSize: 14,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required Widget child,
    required Color cardBg,
    required Color borderColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1),
      ),
      padding: const EdgeInsets.all(16.0),
      child: child,
    );
  }

  Widget _buildBreadcrumb(Color textColor) {
    return Row(
      children: [
        Text(
          'Home',
          style: TextStyle(color: textColor, fontSize: 13),
        ),
        Text(' > ', style: TextStyle(color: textColor, fontSize: 13)),
        Text(
          'Giveaways',
          style: TextStyle(color: textColor, fontSize: 13),
        ),
        Text(' > ', style: TextStyle(color: textColor, fontSize: 13)),
        Text(
          game.breadcrumbCategory,
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRarityBadge(GameRarity rarity) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: rarity.color, width: 1.2),
        borderRadius: BorderRadius.circular(4),
        color: rarity.color.withValues(alpha: 0.08),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(rarity.icon, color: rarity.color, size: 14),
          const SizedBox(width: 6),
          Text(
            rarity.label,
            style: TextStyle(
              color: rarity.color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformChip(String platform, bool isDark) {
    final lower = platform.toLowerCase();
    Widget iconWidget = Icon(
      Icons.devices,
      size: 11,
      color: isDark ? Colors.white70 : Colors.black87,
    );

    final iconColor = isDark ? Colors.white70 : Colors.black87;

    if (lower.contains('pc') || lower.contains('windows')) {
      iconWidget = FaIcon(FontAwesomeIcons.windows, size: 11, color: iconColor);
    } else if (lower.contains('steam')) {
      iconWidget = FaIcon(FontAwesomeIcons.steam, size: 11, color: iconColor);
    } else if (lower.contains('playstation') || lower.contains('ps4') || lower.contains('ps5')) {
      iconWidget = FaIcon(FontAwesomeIcons.playstation, size: 11, color: iconColor);
    } else if (lower.contains('xbox')) {
      iconWidget = FaIcon(FontAwesomeIcons.xbox, size: 11, color: iconColor);
    } else if (lower.contains('android')) {
      iconWidget = FaIcon(FontAwesomeIcons.android, size: 11, color: iconColor);
    } else if (lower.contains('ios') || lower.contains('apple')) {
      iconWidget = FaIcon(FontAwesomeIcons.apple, size: 11, color: iconColor);
    } else if (lower.contains('switch') || lower.contains('nintendo')) {
      iconWidget = FaIcon(FontAwesomeIcons.gamepad, size: 11, color: iconColor);
    } else if (lower.contains('itch')) {
      iconWidget = FaIcon(FontAwesomeIcons.itchIo, size: 11, color: iconColor);
    } else if (lower.contains('drm')) {
      iconWidget = Icon(Icons.lock_open, size: 11, color: iconColor);
    } else if (lower.contains('stove')) {
      iconWidget = Icon(Icons.storefront, size: 11, color: iconColor);
    } else if (lower.contains('gog')) {
      iconWidget = Icon(Icons.sports_esports, size: 11, color: iconColor);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B1220) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black12,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget,
          const SizedBox(width: 4),
          Text(
            platform,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required String label,
    required Widget iconWidget,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0B1220) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black12,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
