import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart'; // This connects to your manual file
import 'config/theme.dart';
import 'services/theme_service.dart';
import 'providers/auth_provider.dart';
import 'providers/property_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  // 1. Ensure the Flutter framework is ready
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase using your manual options
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    print("Firebase initialization failed: $e");
  }

  runApp(const AsifiweApp());
}

class AsifiweApp extends StatelessWidget {
  const AsifiweApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PropertyProvider()),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'Asifiwe',
            debugShowCheckedModeBanner: false,
            theme: AsifiweTheme.lightTheme,
            darkTheme: AsifiweTheme.darkTheme,
            themeMode: themeService.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
