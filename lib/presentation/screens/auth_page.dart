// lib/presentation/screens/auth_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loan_project/core/services/auth_page_services.dart';
import 'package:loan_project/core/services/admin_dashboard_services.dart';
import 'package:loan_project/presentation/screens/admin_dashboard.dart';
import 'package:loan_project/presentation/screens/user_dashboard.dart';

/// =====================
/// Auth UI (Login / Admin Login)
/// =====================

class AppColors {
  static const primary = Color(0xFFFF9800);
  static const primaryDark = Color(0xFFF57C00);
  static const bgLight = Color(0xFFFAFAFA);
}

InputDecoration customInputDecoration({
  required String hint,
  required IconData icon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, color: Colors.grey.shade400),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: AppColors.bgLight,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.primary),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}

String? emailValidator(String? value) {
  if (value == null || value.trim().isEmpty) return 'Please enter your email';
  if (!RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
    return 'Please enter a valid email';
  }
  return null;
}

String? passwordValidator(String? value, {int minLen = 6}) {
  if (value == null || value.isEmpty) return 'Please enter your password';
  if (value.length < minLen)
    return 'Password must be at least $minLen characters';
  return null;
}

Widget primaryButton({
  required String text,
  required VoidCallback? onPressed,
  bool loading = false,
}) {
  return SizedBox(
    width: double.infinity,
    height: 50,
    child: ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(
              text,
              style: GoogleFonts.workSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
    ),
  );
}

Widget authRightPanel({
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primary, AppColors.primaryDark],
      ),
    ),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 110, color: Colors.white),
          const SizedBox(height: 18),
          Text(
            title,
            style: GoogleFonts.workSans(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.workSans(fontSize: 14, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class AuthScaffold extends StatelessWidget {
  final Widget form;
  final Widget infoPanel;
  const AuthScaffold({super.key, required this.form, required this.infoPanel});

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 900;
    if (wide) {
      return Row(
        children: [
          Expanded(flex: 5, child: form),
          Expanded(flex: 4, child: infoPanel),
        ],
      );
    } else {
      return SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 260, child: infoPanel),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: form,
            ),
          ],
        ),
      );
    }
  }
}

/// ===================== LOGIN PAGE =====================
class LoginPage extends StatefulWidget {
  static const routeName = '/login';
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  final _authService = AuthPageServices();
  final _adminService = AdminDashboardServices();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final result = await _authService.signInWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;
    if (result.success) {
      // check role
      final bool admin = await _adminService.isAdmin();
      if (!mounted) return;
      if (admin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const UserDashboardPage()),
        );
      }
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.error ?? 'Login failed')));
    }
  }

  void _goToAdminLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminLoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final form = Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PayAdvance',
                style: GoogleFonts.workSans(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Welcome back! Please sign in to your account.',
                style: GoogleFonts.workSans(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email Address',
                      style: GoogleFonts.workSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: customInputDecoration(
                        hint: 'Enter your email',
                        icon: Icons.email_outlined,
                      ),
                      validator: emailValidator,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Password',
                      style: GoogleFonts.workSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: customInputDecoration(
                        hint: 'Enter your password',
                        icon: Icons.lock_outlined,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey.shade400,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      validator: (v) => passwordValidator(v, minLen: 6),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: Text(
                          'Forgot Password?',
                          style: GoogleFonts.workSans(color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    primaryButton(
                      text: 'Sign In',
                      onPressed: _submit,
                      loading: _isLoading,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'or',
                            style: GoogleFonts.workSans(
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    primaryButton(
                      text: 'Sign in with Google',
                      onPressed: () async {
                        setState(() => _isLoading = true);
                        final result = await _authService.signInWithGoogle();
                        if (!mounted) return;

                        if (result.success) {
                          final bool admin = await _adminService.isAdmin();
                          if (!mounted) return;
                          if (admin) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminDashboardPage(),
                              ),
                            );
                          } else {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const UserDashboardPage(),
                              ),
                            );
                          }
                        } else {
                          setState(() => _isLoading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                result.error ?? 'Google sign in failed',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: _goToAdminLogin,
                      child: Center(
                        child: Text(
                          'Admin Login',
                          style: GoogleFonts.workSans(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: AuthScaffold(
        form: form,
        infoPanel: authRightPanel(
          icon: Icons.login,
          title: 'Welcome Back',
          subtitle: 'Sign in to continue using PayAdvance',
        ),
      ),
    );
  }
}

/// ===================== ADMIN LOGIN PAGE =====================
class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _tryAdminLogin() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter admin email')));
      return;
    }

    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _loading = false);

    if (email.toLowerCase() == 'admin@payadvance.local') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid admin id')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Login')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Card(
            margin: const EdgeInsets.all(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Admin Sign In',
                    style: GoogleFonts.workSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailCtrl,
                    decoration: customInputDecoration(
                      hint: 'Admin email',
                      icon: Icons.email_outlined,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _tryAdminLogin,
                      child: Text(_loading ? 'Signing in...' : 'Sign in'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
