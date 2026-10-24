import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import '../apps/my_app.dart';
import '../providers/theme_notifier_provider.dart';
import 'game_screen.dart';
import 'settings_screen.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watching the providers keeps them reactive across all tabs
    final currentColorIndex = ref.watch(colorNotifierProvider);
    final isDarkMode = ref.watch(themeNotifierProvider);
    final selectedColor = colorList[currentColorIndex];

    return PersistentTabView(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      tabs: [
        PersistentTabConfig(
          screen: const GameScreen(),
          item: ItemConfig(
            icon: const Icon(Icons.home),
            title: "Home",
            activeForegroundColor: selectedColor,
            inactiveForegroundColor: isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
        PersistentTabConfig(
          screen: Container(
            color: isDarkMode ? const Color(0xFF121212) : Colors.blue,
          ),
          item: ItemConfig(
            icon: const Icon(Icons.message),
            title: "Messages",
            activeForegroundColor: selectedColor,
            inactiveForegroundColor: isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
        PersistentTabConfig(
          screen: const SettingsScreen(),
          item: ItemConfig(
            icon: const Icon(Icons.settings),
            title: "Settings",
            activeForegroundColor: selectedColor,
            inactiveForegroundColor: isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
      ],
      navBarBuilder: (navBarConfig) => Style9BottomNavBar(
        navBarConfig: navBarConfig,
        navBarDecoration: NavBarDecoration(
          color: selectedColor.withValues(alpha: isDarkMode ? 0.35 : 0.6),
        ),
      ),
    );
  }
}