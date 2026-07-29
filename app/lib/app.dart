import 'package:flutter/material.dart';

/// Root widget. Wiring for theming, routing and localisation lands here in
/// Phase 1; this placeholder only proves the toolchain boots.
class MasterOpeningApp extends StatelessWidget {
  const MasterOpeningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MasterOpening',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF968AE0)),
        fontFamily: 'Inter',
      ),
      home: const Scaffold(
        body: Center(child: Text('MasterOpening')),
      ),
    );
  }
}
