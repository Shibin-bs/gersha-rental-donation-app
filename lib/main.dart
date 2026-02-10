import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/firebase_service.dart';
import 'services/sample_data_service.dart';
import 'providers/auth_provider.dart';
import 'providers/listing_provider.dart';
import 'screens/auth_wrapper_screen.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase - this must complete before runApp
    await Firebase.initializeApp();
    debugPrint('[OK] [main] Firebase.initializeApp() completed');
    
    // Initialize Firebase services
    await FirebaseService.initialize();
    
    // Create sample data on first launch (optional - can be removed in production)
    // This populates Firestore with test listings for testing
    await SampleDataService.createSampleDataIfNeeded();
  } catch (e, stackTrace) {
    // Log error but continue - Firebase might not be configured yet
    debugPrint('[ERROR] [main] Firebase initialization error: $e');
    debugPrint('Stack trace: $stackTrace');
  }
  
  // Run the app with Provider
  runApp(const GershaApp());
}

/// Main app widget with Provider setup
class GershaApp extends StatelessWidget {
  const GershaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth provider for authentication state
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // Listing provider for listings state
        ChangeNotifierProvider(create: (_) => ListingProvider()),
      ],
      child: MaterialApp(
        title: 'GERSHA',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          // Light theme - white classic design
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 2,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          scaffoldBackgroundColor: Colors.white,
        ),
        darkTheme: ThemeData(
          // Dark theme
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 2,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        themeMode: ThemeMode.system, // Follow system theme
        home: const AuthWrapperScreen(),
      ),
    );
  }
}
