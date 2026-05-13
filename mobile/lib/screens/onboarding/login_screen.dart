import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/back_button.dart';
import '../../widgets/primitives.dart';
import '../main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _otpSent = false;
  int _resendIn = 0;
  Timer? _timer;
  String? _error;
  String _country = '+91';
  String _fullPhone = '';

  @override
  void dispose() {
    _timer?.cancel();
    _phoneCtrl.dispose(); _otpCtrl.dispose(); _nameCtrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    _resendIn = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_resendIn > 0) _resendIn--;
        if (_resendIn == 0) t.cancel();
      });
    });
  }

  Future<void> _sendOtp() async {
    setState(() => _error = null);
    final raw = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (raw.length < 6) {
      setState(() => _error = 'Enter a valid phone number');
      return;
    }
    _fullPhone = '$_country$raw';
    final auth = context.read<AuthProvider>();
    if (!auth.firebaseConfigured) {
      setState(() => _error = 'Phone auth has not been configured. Ask an admin to set up Firebase.');
      return;
    }
    try {
      final autoSignedIn = await auth.firebaseSendOtp(
        _fullPhone,
        name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      );
      if (!mounted) return;
      if (autoSignedIn) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainShell()), (_) => false,
        );
        return;
      }
      setState(() { _otpSent = true; });
      _startTimer();
    } catch (e) {
      if (mounted) setState(() => _error = auth.error ?? e.toString());
    }
  }

  Future<void> _verify() async {
    setState(() => _error = null);
    try {
      await context.read<AuthProvider>().firebaseVerifyOtp(
        _otpCtrl.text.trim(),
        name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()), (_) => false,
      );
    } catch (e) {
      if (mounted) setState(() => _error = context.read<AuthProvider>().error ?? e.toString());
    }
  }

  Future<void> _resend() async {
    if (_resendIn > 0) return;
    await _sendOtp();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: VTokens.bg,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(top: 12, left: 20, child: VBackButton(onTap: () => Navigator.of(context).maybePop())),
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 80, 28, 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_otpSent ? 'Verify your\nnumber' : 'Sign in to\nVacado',
                    style: AppTheme.serif(size: 34, letterSpacing: -.6)),
                  const SizedBox(height: 12),
                  Text(
                    _otpSent
                      ? 'We sent a 6-digit code to $_fullPhone'
                      : 'Enter your mobile number — we will send a one-time code over SMS.',
                    style: const TextStyle(fontSize: 14, color: VTokens.ink3, height: 1.5),
                  ),
                  const SizedBox(height: 28),
                  if (!_otpSent) _phoneFields() else _otpField(),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(10)),
                      child: Text(_error!, style: const TextStyle(color: VTokens.rose700, fontSize: 12)),
                    ),
                  ],
                  if (!auth.firebaseConfigured) ...[
                    const SizedBox(height: 20),
                    _infoCard(
                      'Phone auth not configured yet',
                      'An administrator needs to add the Firebase keys in the admin console before users can sign in.',
                    ),
                  ],
                  if (_otpSent) ...[
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _resendIn > 0
                          ? Text.rich(TextSpan(
                              text: 'Resend code in ',
                              style: const TextStyle(fontSize: 13, color: VTokens.ink3),
                              children: [
                                TextSpan(
                                  text: '0:${_resendIn.toString().padLeft(2, '0')}',
                                  style: const TextStyle(color: VTokens.ink, fontWeight: FontWeight.w800,
                                    fontFeatures: [FontFeature.tabularFigures()]),
                                ),
                              ],
                            ))
                          : GestureDetector(
                              onTap: _resend,
                              child: const Text('Resend code',
                                style: TextStyle(color: VTokens.green700, fontWeight: FontWeight.w800, fontSize: 13)),
                            ),
                        const Row(children: [
                          Icon(Icons.sms_outlined, size: 14, color: VTokens.ink3),
                          SizedBox(width: 6),
                          Text('via Firebase SMS', style: TextStyle(fontSize: 13, color: VTokens.ink3)),
                        ]),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              left: 24, right: 24, bottom: 24,
              child: PrimaryBtn(
                label: auth.loading
                  ? (_otpSent ? 'Verifying…' : 'Sending…')
                  : (_otpSent ? 'Verify & continue' : 'Send OTP'),
                fullWidth: true,
                onPressed: auth.loading ? null : (_otpSent ? _verify : _sendOtp),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _phoneFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nameCtrl,
          decoration: _input('Your name (optional)', 'Riya Sharma'),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        Row(children: [
          SizedBox(
            width: 92,
            child: DropdownButtonFormField<String>(
              value: _country,
              isExpanded: true,
              decoration: _input('Code', null),
              items: const [
                DropdownMenuItem(value: '+91', child: Text('🇮🇳 +91')),
                DropdownMenuItem(value: '+1',  child: Text('🇺🇸 +1')),
                DropdownMenuItem(value: '+44', child: Text('🇬🇧 +44')),
                DropdownMenuItem(value: '+971', child: Text('🇦🇪 +971')),
                DropdownMenuItem(value: '+61', child: Text('🇦🇺 +61')),
              ],
              onChanged: (v) => setState(() => _country = v ?? '+91'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(15)],
              decoration: _input('Mobile number', '98765 43210'),
            ),
          ),
        ]),
        const SizedBox(height: 14),
        const Text(
          'By continuing you agree to our Terms & Privacy. SMS charges may apply.',
          style: TextStyle(fontSize: 11, color: VTokens.ink3, height: 1.5),
        ),
      ],
    );
  }

  Widget _otpField() {
    final default_ = PinTheme(
      width: 48, height: 56,
      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
      decoration: BoxDecoration(
        color: VTokens.surface,
        border: Border.all(color: VTokens.line, width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
    );
    final focused = default_.copyDecorationWith(
      border: Border.all(color: VTokens.green, width: 1.5),
      color: VTokens.green25,
    );
    final submitted = default_.copyDecorationWith(
      border: Border.all(color: VTokens.green50, width: 1.5),
      color: VTokens.green25,
    );

    return Pinput(
      length: 6,
      controller: _otpCtrl,
      defaultPinTheme: default_,
      focusedPinTheme: focused,
      submittedPinTheme: submitted,
      autofocus: true,
      onCompleted: (_) => _verify(),
    );
  }

  Widget _infoCard(String title, String body) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: VTokens.green25, borderRadius: BorderRadius.circular(14),
      border: Border.all(color: VTokens.green50),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(color: VTokens.green, borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: VTokens.ink)),
            const SizedBox(height: 2),
            Text(body, style: const TextStyle(fontSize: 12, color: VTokens.ink2, height: 1.4)),
          ],
        ),
      ),
    ]),
  );

  InputDecoration _input(String label, String? hint) => InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: VTokens.surface,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: VTokens.line)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: VTokens.line)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: VTokens.green, width: 1.5)),
  );
}
