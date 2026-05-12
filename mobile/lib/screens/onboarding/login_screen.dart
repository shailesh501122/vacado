import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import '../../core/env.dart';
import '../../providers/auth_provider.dart';
import '../../theme/tokens.dart';
import '../../theme/app_theme.dart';
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
  int _resendIn = 24;
  Timer? _timer;
  String? _error;

  @override
  void dispose() {
    _timer?.cancel();
    _phoneCtrl.dispose(); _otpCtrl.dispose(); _nameCtrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    _resendIn = 24;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_resendIn > 0) _resendIn--;
        if (_resendIn == 0) t.cancel();
      });
    });
  }

  Future<void> _requestOtp() async {
    setState(() => _error = null);
    final phone = _phoneCtrl.text.replaceAll(' ', '').trim();
    if (phone.length < 8) {
      setState(() => _error = 'Enter a valid phone number');
      return;
    }
    try {
      await context.read<AuthProvider>().requestOtp(phone);
      setState(() => _otpSent = true);
      _startTimer();
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _verify() async {
    setState(() => _error = null);
    try {
      await context.read<AuthProvider>().verifyOtp(_otpCtrl.text.trim(), name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim());
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const MainShell()), (_) => false);
    } catch (e) {
      setState(() => _error = e.toString());
    }
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
              padding: const EdgeInsets.fromLTRB(28, 80, 28, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_otpSent ? 'Verify your\nnumber' : 'Sign in to\nVacado',
                    style: AppTheme.serif(size: 34, letterSpacing: -.6)),
                  const SizedBox(height: 12),
                  Text(
                    _otpSent
                      ? 'We sent a 6-digit code to +91 ${_phoneCtrl.text}'
                      : 'Enter your mobile number to get started',
                    style: const TextStyle(fontSize: 14, color: VTokens.ink3, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  if (!_otpSent) _phoneField() else _otpField(),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(8)),
                      child: Text(_error!, style: const TextStyle(color: VTokens.rose700, fontSize: 12)),
                    ),
                  ],
                  if (_otpSent) ...[
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text.rich(TextSpan(
                          text: _resendIn > 0 ? 'Resend code in ' : 'Didn\'t get it? ',
                          style: const TextStyle(fontSize: 13, color: VTokens.ink3),
                          children: [
                            if (_resendIn > 0)
                              TextSpan(text: '0:${_resendIn.toString().padLeft(2, '0')}',
                                style: const TextStyle(color: VTokens.ink, fontWeight: FontWeight.w800, fontFeatures: [FontFeature.tabularFigures()]))
                            else
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: _requestOtp,
                                  child: const Text('Resend', style: TextStyle(color: VTokens.green700, fontWeight: FontWeight.w800, fontSize: 13)),
                                ),
                              ),
                          ],
                        )),
                        const Row(children: [
                          Icon(Icons.chat_bubble_outline, size: 14, color: VTokens.ink3),
                          SizedBox(width: 6),
                          Text('via WhatsApp', style: TextStyle(fontSize: 13, color: VTokens.ink3)),
                        ]),
                      ],
                    ),
                    if (Env.devShowOtp && auth.devCode != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: VTokens.green25, borderRadius: BorderRadius.circular(14), border: Border.all(color: VTokens.green50)),
                        child: Text('DEV bypass code: ${auth.devCode}',
                          style: const TextStyle(color: VTokens.green700, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ],
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: VTokens.green25, borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: VTokens.green50),
                    ),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(width: 32, height: 32,
                        decoration: BoxDecoration(color: VTokens.green, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Truecaller verification ready', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: VTokens.ink)),
                            SizedBox(height: 2),
                            Text('Skip the code — verify in one tap with your Truecaller account.',
                              style: TextStyle(fontSize: 12, color: VTokens.ink2, height: 1.4)),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 24, right: 24, bottom: 24,
              child: PrimaryBtn(
                label: _otpSent ? (auth.loading ? 'Verifying…' : 'Verify & continue') : (auth.loading ? 'Sending…' : 'Send OTP'),
                fullWidth: true,
                onPressed: auth.loading ? null : (_otpSent ? _verify : _requestOtp),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _phoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nameCtrl,
          decoration: _input('Your name', 'Riya Sharma'),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _input('Mobile number', '+91 98765 43210', icon: Icons.phone_iphone_rounded),
        ),
      ],
    );
  }

  Widget _otpField() {
    final default_ = PinTheme(
      width: 50, height: 56,
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

  InputDecoration _input(String label, String hint, {IconData? icon}) => InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: icon != null ? Icon(icon, color: VTokens.ink3) : null,
    filled: true,
    fillColor: VTokens.surface,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: VTokens.line)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: VTokens.line)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: VTokens.green, width: 1.5)),
  );
}
