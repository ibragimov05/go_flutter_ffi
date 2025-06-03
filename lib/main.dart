import 'package:flutter/material.dart';

import 'home_screen.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Flutter Go FFI Bridge',
    theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
    home: const HomeScreen(),
  );
}
