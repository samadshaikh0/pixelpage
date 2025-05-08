import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:pixelpage/src/pages/home.dart'; // adjust path as per your project
import 'package:pixelpage/src/pages/Auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


void main() async {
  await GetStorage.init();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final box  = GetStorage();
    final isLoggedIn = box.read('isLoggedIn');

    return MaterialApp(
      title: 'Pixel Page',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: isLoggedIn == true ? '/home' : '/',
      routes: {
        '/': (context) => const AuthPage(),    // or HomePage if already logged in
        '/home': (context) => const HomePage(), // 👈 define this
      },
    );
  }
}
