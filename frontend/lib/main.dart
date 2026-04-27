import 'package:flutter/material.dart';
import 'core/router.dart';
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router, // ← Aquí usas router.dart
    );
  }
}
