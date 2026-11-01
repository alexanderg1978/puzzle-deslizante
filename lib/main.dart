import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/progress.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final progress = await Progress.load();
  progress.restoreUser();
  runApp(PuzzleApp(progress: progress));
}

class PuzzleApp extends StatelessWidget {
  const PuzzleApp({super.key, required this.progress});
  final Progress progress;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Puzzle Deslizante',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3F51B5)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3F51B5),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: ListenableBuilder(
        listenable: progress,
        builder: (context, _) => progress.hasSession
            ? HomeScreen(progress: progress)
            : LoginScreen(progress: progress),
      ),
    );
  }
}
