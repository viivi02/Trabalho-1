import 'package:flutter/material.dart';
import 'screens/orders_screen.dart';

void main() {
  runApp(const OrdersDashboardApp());
}

class OrdersDashboardApp extends StatelessWidget {
  const OrdersDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orders Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1565C0),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF42A5F5),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.dark,
      home: const OrdersScreen(),
    );
  }
}
