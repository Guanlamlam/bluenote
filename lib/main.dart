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

class AuthChecker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Debugging: Check connection state
        print('Auth state connection: ${snapshot.connectionState}');

        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData) {
            // User is logged in, navigate to HomeScreen
            print('User is authenticated: ${snapshot.data?.email}');
            return HomeScreen();
          } else {
            // User is not logged in, navigate to LoginScreen
            print('No authenticated user found.');
            return LoginScreen();
          }
        } else {
          // Waiting for authentication state, show loading spinner
          print('Waiting for authentication state...');
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
