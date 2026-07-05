import 'package:flutter/material.dart';
import 'package:family_safety_tracker/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;

  Future<void> _sendOtp() async {
    await AuthService().signInWithPhone(_phoneController.text);
    setState(() => _otpSent = true);
  }

  Future<void> _verifyOtp() async {
    await AuthService().verifyOtp(_otpController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Family Safety')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
            ),
            if (_otpSent) ...[
              TextField(
                controller: _otpController,
                decoration: const InputDecoration(labelText: 'SMS Code'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _verifyOtp, child: const Text('Verify')),
            ] else ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: _sendOtp, child: const Text('Send OTP')),
            ],
          ],
        ),
      ),
    );
  }
}
