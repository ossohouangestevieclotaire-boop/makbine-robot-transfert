import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/robot_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://vxaqlbaqfpxitbdimeqj.supabase.co',
    anonKey: 'sb_publishable_otC4yztme4tqkL9BA8FM5Q_APYQrtGe',
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
