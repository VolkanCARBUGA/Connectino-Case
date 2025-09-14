import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:my_notes/firebase_options.dart';
import 'package:my_notes/pages/auth/login_page.dart';
import 'package:my_notes/pages/auth/signup_page.dart';
import 'package:my_notes/pages/create_note.dart';
import 'package:my_notes/pages/notes_page.dart';
import 'package:my_notes/providers/auth_provider.dart';
import 'package:my_notes/providers/notes_provider.dart';
import 'package:my_notes/services/connectivity_service.dart';
import 'package:my_notes/services/local_storage_service.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await ConnectivityService.instance.initialize(onConnectivityChanged: (bool isConnected) async {});
  
  // LocalStorageService'i initialize et
  final localStorageService = LocalStorageService();
  await localStorageService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => NotesProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => AuthProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return MaterialApp(
          title: 'My Notes',
          initialRoute: authProvider.user != null ? '/notes' : '/login',
          routes: {
            '/notes': (context) => const NotesPage(),
            '/login': (context) => const LoginPage(),
            '/signup': (context) => const SignupPage(),
            '/addNote': (context) => const CreateNote(),
          },
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          ),
        );
      },
    );
  }
}
