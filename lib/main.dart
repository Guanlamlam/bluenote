
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'firebase_options.dart';


void main() async {
  // Initialize Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: AuthChecker(), // Checking authentication here
    );
  }
}

class AuthChecker extends StatefulWidget {
  @override
  _AuthCheckerState createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> {
  bool _showSplash = true;
  User? _user;

  @override
  void initState() {
    super.initState();
    // Start splash + check auth
    Future.delayed(Duration(seconds: 1), () {
      FirebaseAuth.instance.authStateChanges().first.then((user) {
        setState(() {
          _user = user;
          _showSplash = false;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(); // Show app logo
    } else if (_user != null) {
      return HomeScreen(); // User logged in
    } else {
      return LoginScreen(); // User not logged in
    }
  }
}


class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // match your splash theme
      body: Center(
        child: Image.asset(
          'assets/app_icon.png',
          width: 150,
        ),
      ),
    );
  }
}

