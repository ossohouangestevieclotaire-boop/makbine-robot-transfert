import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/robot_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://vxaqlbaqfpxitbdimeqj.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ4YXFsYmFxZnB4aXRiZGltZXFqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODYyNjQ3NjAsImV4cCI6MjEwMTg0MDc2MH0.izqAjAoKSz_ecnuppy1XEcJWcsvDc-wwoJqdUR8coDI',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Makbine Robot',
      home: const RobotTransfertScreen(),
      theme: ThemeData(primarySwatch: Colors.amber),
      debugShowCheckedModeBanner: false,
    );
  }
}
