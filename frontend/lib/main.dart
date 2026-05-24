import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/garden_state.dart';
import 'features/navigation/main_navigation_wrapper.dart';
import 'features/auth/screens/auth_screen.dart';

void main() async {
  // Ensure Flutter engine is initialized before reading local storage
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  
  // Initialize state and load user progress / garden coordinates from local cache
  final state = GardenState();
  if (token != null) {
    await state.init();
  }

  runApp(SentiaApp(initialRouteIsHome: token != null));
}

class SentiaApp extends StatelessWidget {
  final bool initialRouteIsHome;
  
  const SentiaApp({super.key, required this.initialRouteIsHome});

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
      home: initialRouteIsHome ? const MainNavigationWrapper() : const AuthScreen(),
    );
  }
}

