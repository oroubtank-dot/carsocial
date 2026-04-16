import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import '../constants/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _isLoading = false;
  bool _isOtpSent = false;
  String? _verificationId;
  String _identifierType = 'email'; // 'email' or 'phone'
  String _identifier = '';

  Future<void> _sendOtp() async {
    final identifier = _identifierController.text.trim();

    if (identifier.isEmpty) {
      _showSnackBar('الرجاء إدخال البريد الإلكتروني أو رقم الهاتف');
      return;
    }

    if (_passwordController.text.isEmpty) {
      _showSnackBar('الرجاء إدخال كلمة المرور');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('كلمة المرور غير متطابقة');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (identifier.contains('@')) {
        // إرسال كود عبر البريد الإلكتروني
        _identifierType = 'email';
        _identifier = identifier;
        await _sendEmailOtp(identifier);
      } else {
        // إرسال كود عبر الهاتف
        _identifierType = 'phone';
        _identifier = identifier;
        await _sendPhoneOtp(identifier);
      }

      setState(() {
        _isOtpSent = true;
        _isLoading = false;
      });

      _showSnackBar('تم إرسال رمز التحقق', isError: false);
    } catch (e) {
      _showSnackBar('حدث خطأ: ${e.toString()}');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendEmailOtp(String email) async {
    // إنشاء مستخدم مؤقت في Firebase Auth
    final auth = FirebaseAuth.instance;
    await auth.createUserWithEmailAndPassword(
      email: email,
      password: _passwordController.text.trim(),
    );

    // إرسال إيميل تحقق
    final user = auth.currentUser;
    await user?.sendEmailVerification();

    _verificationId = user?.uid;
  }

  Future<void> _sendPhoneOtp(String phone) async {
    final auth = FirebaseAuth.instance;
    await auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (credential) async {
        await auth.signInWithCredential(credential);
        _completeRegistration();
      },
      verificationFailed: (e) {
        _showSnackBar('فشل إرسال الكود: ${e.message}');
      },
      codeSent: (verificationId, forceResendingToken) {
        _verificationId = verificationId;
      },
      codeAutoRetrievalTimeout: (verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      _showSnackBar('الرجاء إدخال رمز التحقق');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_identifierType == 'email') {
        // التحقق من البريد الإلكتروني
        final user = FirebaseAuth.instance.currentUser;
        await user?.reload();
        if (user?.emailVerified ?? false) {
          await _completeRegistration();
        } else {
          _showSnackBar('الرجاء التحقق من بريدك الإلكتروني أولاً');
          setState(() => _isLoading = false);
        }
      } else {
        // التحقق من الهاتف
        final credential = PhoneAuthProvider.credential(
          verificationId: _verificationId!,
          smsCode: otp,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
        await _completeRegistration();
      }
    } catch (e) {
      _showSnackBar('رمز التحقق غير صحيح: ${e.toString()}');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _completeRegistration() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // حفظ بيانات المستخدم في Firestore
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': _identifierType == 'email' ? _identifier : '',
      'phoneNumber': _identifierType == 'phone' ? _identifier : '',
      'createdAt': FieldValue.serverTimestamp(),
      'accountType': 'free',
      'points': 0,
      'level': 1,
    });

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/edit_profile');
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'register'.tr(),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'create_account'.tr(),
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),
              if (!_isOtpSent) ...[
                // حقل البريد أو الهاتف
                TextField(
                  controller: _identifierController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'البريد الإلكتروني أو رقم الهاتف',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    helperText: 'أدخل بريدك الإلكتروني أو رقم هاتفك',
                  ),
                ),
                const SizedBox(height: 16),

                // كلمة المرور
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'password'.tr(),
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                // تأكيد كلمة المرور
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'confirm_password'.tr(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text('إرسال رمز التحقق',
                            style: const TextStyle(fontSize: 16)),
                  ),
                ),
              ],
              if (_isOtpSent) ...[
                Text(
                  'تم إرسال رمز التحقق إلى ${_identifierType == 'email' ? 'بريدك الإلكتروني' : 'هاتفك'}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'رمز التحقق',
                    prefixIcon: const Icon(Icons.pin),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text('تأكيد', style: const TextStyle(fontSize: 16)),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('لديك حساب بالفعل؟',
                      style: TextStyle(color: Colors.grey.shade600)),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: Text('تسجيل الدخول',
                        style: TextStyle(color: AppColors.primary)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
