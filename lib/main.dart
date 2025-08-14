import 'package:flutter/material.dart';
import 'package:loan_project/presentation/screens/admin_dashboard.dart';
import 'package:loan_project/presentation/screens/auth_page.dart';
import 'package:loan_project/presentation/screens/user_dashboard.dart';
import 'presentation/screens/landing_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Company Name',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const AdminDashboard(),
      debugShowCheckedModeBanner: false,
    );
  }
}
