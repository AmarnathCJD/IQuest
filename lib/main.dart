import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';
import 'game_page.dart';
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const IQuestApp());
}
class IQuestApp extends StatelessWidget {
  const IQuestApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IQUEST / Social Development',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const GamePage(),
    );
  }
}
