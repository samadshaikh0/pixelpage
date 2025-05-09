import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class RedirectPage extends StatelessWidget {
  const RedirectPage({super.key});

  @override
  Widget build(BuildContext context) {
    final box = GetStorage();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isLoggedIn = box.read('isLoggedIn') ?? false;
      Navigator.pushReplacementNamed(context, isLoggedIn ? '/home' : '/auth');
    });

    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
