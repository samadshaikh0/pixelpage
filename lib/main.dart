import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import './src/pages/home.dart';
import './src/pages/auth.dart';
import './src/pages/redirect.dart'; // 👈 create this page




void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pixel Page',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/redirect',
      routes: {
        '/redirect': (_) => const RedirectPage(),
        '/auth': (_) => const AuthPage(),
        '/home': (_) => const HomePage(),
      },
    );
  }
}
