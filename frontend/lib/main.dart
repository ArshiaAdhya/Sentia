import 'package:flutter/material.dart';
import 'features/garden_state.dart';
import 'features/navigation/main_navigation_wrapper.dart';

void main() async {
  // Ensure Flutter engine is initialized before reading local storage
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize state and load user progress / garden coordinates from local cache
  final state = GardenState();
  await state.init();

  runApp(const SentiaApp());
}

class SentiaApp extends StatelessWidget {
  const SentiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sentia AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B5E43),
          primary: const Color(0xFF3B5E43),
        ),
        useMaterial3: true,
      ),
      home: const MainNavigationWrapper(),
    );
  }
}
