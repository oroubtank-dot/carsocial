import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/biometric_service.dart';
import '../utils/toast_helper.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  bool _isPasswordStep = false;
  bool _isBiometricEnabled = false;
  bool _isLoadingBiometric = true;

  @override
  void initState() {
    super.initState();
    _loadBiometricStatus();
  }

  Future<void> _loadBiometricStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final isEnabled = await BiometricService.isBiometricEnabled(user.uid);
      setState(() {
        _isBiometricEnabled = isEnabled;
        _isLoadingBiometric = false;
      });
    } else {
      setState(() => _isLoadingBiometric = false);
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (value) {
      final authenticated = await BiometricService.authenticate(
        reason: 'enable_biometric'.tr(),
      );
      if (authenticated) {
        await BiometricService.setBiometricEnabled(user.uid, true);
        setState(() => _isBiometricEnabled = true);
        if (mounted) {
          ToastHelper.showSuccess('تم تفعيل البصمة بنجاح');
        }
      }
    } else {
      await BiometricService.setBiometricEnabled(user.uid, false);
      setState(() => _isBiometricEnabled = false);
      if (mounted) {
        ToastHelper.showWarning('تم إلغاء تفعيل البصمة');
      }
    }
  }

  Future<void> _continueWithEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ToastHelper.showWarning('please_enter_email'.tr());
      return;
    }

    setState(() {
      _isPasswordStep = true;
    });
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (password.isEmpty) {
      ToastHelper.showWarning('please_enter_password'.tr());
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
        ToastHelper.showSuccess('تم تسجيل الدخول بنجاح');
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found') {
        message = 'no_account_found'.tr();
      } else if (e.code == 'wrong-password') {
        message = 'wrong_password'.tr();
      } else {
        message = 'error_occurred'.tr();
      }
      ToastHelper.showError(message);
    } catch (e) {
      ToastHelper.showError('unexpected_error'.tr());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ToastHelper.showWarning('please_enter_email_first'.tr());
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      ToastHelper.showSuccess('reset_email_sent'.tr());
    } catch (e) {
      ToastHelper.showError('error_check_email'.tr());
    }
  }

  void _backToEmail() {
    setState(() {
      _isPasswordStep = false;
      _passwordController.clear();
    });
  }

  void _continueAsGuest() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
    ToastHelper.showInfo('الدخول كزائر');
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? iconColor,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black87,
          side: const BorderSide(color: Colors.grey),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 12),
            Text(label,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _isPasswordStep
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: _backToEmail,
              )
            : null,
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_car, color: Color(0xFF0066CC), size: 28),
            SizedBox(width: 8),
            Text('CarSocial',
                style: TextStyle(
                    color: Color(0xFF0066CC),
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon:
                const Icon(Icons.language, color: Color(0xFF0066CC), size: 28),
            onSelected: (String language) {
              context.setLocale(Locale(language));
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'ar',
                child: Row(
                  children: [
                    const Text('🇪🇬'),
                    const SizedBox(width: 8),
                    Text('arabic'.tr()),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'en',
                child: Row(
                  children: [
                    const Text('🇬🇧'),
                    const SizedBox(width: 8),
                    Text('english'.tr()),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  _isPasswordStep ? 'enter_password'.tr() : 'login_signup'.tr(),
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                const SizedBox(height: 30),
                if (!_isPasswordStep) ...[
                  Text('email_or_phone'.tr(),
                      style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'enter_email_or_phone'.tr(),
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.grey)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.grey)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF0066CC), width: 2)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                ],
                if (_isPasswordStep) ...[
                  Text('password'.tr(),
                      style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'enter_password_hint'.tr(),
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.grey)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.grey)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF0066CC), width: 2)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: _resetPassword,
                      child: Text('forgot_password'.tr(),
                          style: const TextStyle(
                              color: Color(0xFF0066CC), fontSize: 14)),
                    ),
                  ),
                ],
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : (_isPasswordStep ? _signIn : _continueWithEmail),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066CC),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(_isPasswordStep ? 'sign_in'.tr() : 'next'.tr(),
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                if (!_isPasswordStep) ...[
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('or'.tr(),
                            style: TextStyle(color: Colors.grey.shade600)),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSocialButton(
                    icon: Icons.g_mobiledata,
                    label: 'sign_in_with_google'.tr(),
                    onPressed: () =>
                        ToastHelper.showInfo('قريباً - Google Sign-In'),
                    iconColor: Colors.red,
                  ),
                  const SizedBox(height: 12),
                  _buildSocialButton(
                    icon: Icons.facebook,
                    label: 'sign_in_with_facebook'.tr(),
                    onPressed: () =>
                        ToastHelper.showInfo('قريباً - Facebook Sign-In'),
                    iconColor: const Color(0xFF1877F2),
                  ),
                  const SizedBox(height: 12),
                  _buildSocialButton(
                    icon: Icons.apple,
                    label: 'sign_in_with_apple'.tr(),
                    onPressed: () =>
                        ToastHelper.showInfo('قريباً - Apple Sign-In'),
                    iconColor: Colors.black,
                  ),
                  const SizedBox(height: 24),
                  if (!_isLoadingBiometric && user != null)
                    FutureBuilder<bool>(
                      future: BiometricService.canCheckBiometrics(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data == true) {
                          return Column(
                            children: [
                              SwitchListTile(
                                title: Text('login_with_biometric'.tr()),
                                subtitle: Text('biometric_sub'.tr()),
                                secondary: const Icon(Icons.fingerprint,
                                    color: Color(0xFF0066CC)),
                                value: _isBiometricEnabled,
                                onChanged: _toggleBiometric,
                              ),
                              const SizedBox(height: 12),
                            ],
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _continueAsGuest,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('continue_as_guest'.tr(),
                          style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterScreen())),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0066CC),
                        side: const BorderSide(color: Color(0xFF0066CC)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('create_account'.tr(),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                if (!_isPasswordStep)
                  Center(
                    child: Text(
                      'terms_agreement'.tr(),
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
