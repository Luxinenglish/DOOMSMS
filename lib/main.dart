import 'package:flutter/material.dart';
import 'package:doomsms/theme.dart';
import 'package:doomsms/screens/home_page.dart';

void main() {
  runApp(const DoomSMSApp());
}

class DoomSMSApp extends StatelessWidget {
  const DoomSMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DoomSMS - Messagerie Sécurisée',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}
