import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'balamurugan_data.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const BalamuruganApp());
}

class BalamuruganApp extends StatelessWidget {
  const BalamuruganApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BalamuruganData>.value(
      value: globalData,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Balamurugan Enterprises',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF003366),
            primary: const Color(0xFF003366),
            surface: Colors.white,
            secondary: const Color(0xFFE8EAF6),
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),
        home: const BalamuruganHomeScreen(),
      ),
    );
  }
}
