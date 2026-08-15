import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/app_shell.dart';
import 'screens/login_screen.dart';
import 'services/parking_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  final dataService = ParkingDataService();
  await dataService.init(); // Initialize local persistence

  runApp(const ParkPilotApp());
}

class ParkPilotApp extends StatelessWidget {
  const ParkPilotApp({super.key});

  @override
  Widget build(BuildContext context) {
    final dataService = ParkingDataService();

    return MaterialApp(
      title: 'ParkPilot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF005DAC),
          primary: const Color(0xFF005DAC),
          surface: const Color(0xFFF7F9FC),
          onSurface: const Color(0xFF1E293B),
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Color(0xFF1E293B)),
        ),
      ),
      home: dataService.isLoggedIn ? const AppShell() : const LoginScreen(),
      builder: (context, child) {
        return Container(
          color: const Color(0xFF0F172A),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: ClipRRect(
                borderRadius: MediaQuery.of(context).size.width > 500
                    ? BorderRadius.circular(24)
                    : BorderRadius.zero,
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: MediaQuery.of(context).size.width > 500
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ]
                        : null,
                  ),
                  child: child!,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
