import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_notifier_provider.dart';
import '../screens/main_screen.dart';
import '../screens/detail_screen.dart';

// បញ្ជីពណ៌
List<Color> colorList = [
  Colors.yellow,
  Colors.lime,
  Colors.green,
  Colors.orange,
  Colors.deepOrange,
  Colors.pinkAccent,
  Colors.pink,
  Colors.red,
  Colors.deepPurple,
  Colors.cyanAccent,
  Colors.cyan,
  Colors.lightBlue,
  Colors.blue,
  Colors.indigo,
  Colors.grey,
];

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = ref.watch(themeNotifierProvider);
    final colorIndex = ref.watch(colorNotifierProvider);
    final seedColor = colorList[colorIndex];

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      // home: MainScreen(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (context) => const MainScreen());
          case '/detail':
            return MaterialPageRoute(
              builder: (context) => const DetailScreen(),
              settings: settings,
            );
          default:
            return MaterialPageRoute(
              builder: (context) => const Scaffold(
                body: Center(child: Text("No Screen Found")),
              ),
            );
        }
      },
    );
  }
}