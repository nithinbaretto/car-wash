import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';

class CarWashApp extends StatelessWidget {
  const CarWashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Car Wash',
      theme: AppTheme.light,
      home: const Scaffold(
        body: Center(
          child: Text('Car Wash'),
        ),
      ),
    );
  }
}
