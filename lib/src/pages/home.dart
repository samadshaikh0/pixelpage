import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get_storage/get_storage.dart';
import 'qr_scanner.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final box = GetStorage();
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();

    // Check if logged in
    isLoggedIn = box.read('isLoggedIn') == true;

    // Redirect to Auth if not logged in
    if (!isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/');
      });
    }

    // Listen for changes to isLoggedIn
    box.listenKey('isLoggedIn', (value) {
      setState(() {
        isLoggedIn = value == true;
        if (!isLoggedIn && mounted) {
          Navigator.pushReplacementNamed(context, '/');
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFF007BFF);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Pixel Page'),
        centerTitle: true,
        backgroundColor: themeColor,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_rounded, size: 100, color: themeColor)
                .animate()
                .fadeIn(duration: 800.ms)
                .scale(begin: const Offset(0.6, 0.6), end: const Offset(1.0, 1.0)),
            const SizedBox(height: 24),
            Text(
              'Welcome to Pixel Page!',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: themeColor,
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Scan QR Code'),
              onPressed: () {
                if (isLoggedIn) {
                  Navigator.push(context, _buildAnimatedRoute(const QRScannerPage()));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please login to use this feature"),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: GoogleFonts.poppins(fontSize: 16),
              ),
            ).animate().fadeIn(delay: 400.ms).scale(),
            const SizedBox(height: 20),
            ],
        ),
      ),
    );
  }

  PageRouteBuilder _buildAnimatedRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
  }
}
