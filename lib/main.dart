import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

import 'splash_screen_page.dart';
import 'welcome_page.dart';
import 'register_page.dart';
import 'home_page.dart';
import 'caregiver_home_page.dart';
import 'pairing_page.dart';
import 'login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pole',

      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF570B2),
          brightness: Brightness.dark,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: const Color(0xFF1E293B),
          contentTextStyle: const TextStyle(color: Colors.white),
        ),
      ),

      initialRoute: '/',

      routes: {
        '/': (context) => const AuthWrapper(),

        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),

        '/home': (context) => const HomePage(),
        '/caregiver_home': (context) => const CaregiverHomePage(),
        '/pairing': (context) => const PairingPage(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _showSplash = true;
  bool _isAuthenticated = false;
  bool _isBiometricSupported = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _initAuth();
  }

  Future<void> _initAuth() async {
    final prefs = await SharedPreferences.getInstance();
    _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;

    if (_biometricEnabled) {
      final user = FirebaseAuth.instance.currentUser;
      _isBiometricSupported = await auth.isDeviceSupported();
      
      // Only authenticate if biometric is enabled, supported, AND a user is signed in
      if (_isBiometricSupported && user != null) {
        await _authenticate();
      } else {
        setState(() => _isAuthenticated = true);
      }
    } else {
      setState(() => _isAuthenticated = true);
    }

    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      setState(() {
        _showSplash = false;
      });
    }
  }

  Future<void> _authenticate() async {
    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to access Pole',
      );
      if (mounted) {
        setState(() {
          _isAuthenticated = didAuthenticate;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAuthenticated = true); // Fallback if error occurs
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash || (_biometricEnabled && !_isAuthenticated)) {
      return const SplashScreenPage();
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final User? user = snapshot.data;

          if (user == null) {
            return const WelcomePage();
          }

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get(),
            builder: (context, docSnapshot) {
              if (docSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (docSnapshot.hasData && docSnapshot.data!.exists) {
                final data = docSnapshot.data!.data() as Map<String, dynamic>?;
                String role = data?['role'] ?? 'blind_user';
                if (role == 'caregiver') {
                  return const CaregiverHomePage();
                } else {
                  return const HomePage();
                }
              }

              return const HomePage();
            },
          );
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
