import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:loan_project/presentation/screens/admin_dashboard.dart';
import 'package:loan_project/presentation/screens/testscreen.dart';
import 'firebase_options.dart';
import 'presentation/screens/auth_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PayAdvance - Loan Project',
      theme: ThemeData(primarySwatch: Colors.orange),
      home: LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
