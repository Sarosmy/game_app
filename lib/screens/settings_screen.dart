import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../apps/my_app.dart';
import '../providers/theme_notifier_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeNotifierProvider);
    final selectedColorIndex = ref.watch(colorNotifierProvider);
    final selectedColor = colorList[selectedColorIndex];
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Night Mode',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  Switch(
                    value: isDarkMode,
                    activeThumbColor: selectedColor,
                    activeTrackColor: selectedColor.withValues(alpha: 0.5),
                    onChanged: (value) {
                      ref.read(themeNotifierProvider.notifier).toggleDark();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: colorList.length,
                  itemBuilder: (context, index) {
                    final currentColor = colorList[index];
                    final isSelected = index == selectedColorIndex;

                    return GestureDetector(
                      onTap: () {
                        ref.read(colorNotifierProvider.notifier).changeIndex(index);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: currentColor,
                          borderRadius: BorderRadius.circular(4),
                          border: isSelected
                              ? Border.all(
                                  color: isDarkMode ? Colors.white : Colors.black,
                                  width: 2,
                                )
                              : null,
                        ),
                        child: isSelected
                            ? Center(
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
