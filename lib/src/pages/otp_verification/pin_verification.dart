import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_addons/flutter_addons.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:pinput/pinput.dart';
import 'package:monalisa_app_001/src/components/appbar_builder.dart';
import 'package:monalisa_app_001/src/core/utility/snack_bar.dart';
import 'package:monalisa_app_001/src/pages/biometric_auth/biometric_auth.dart';

class OtpVerificationScreen extends StatefulWidget {
  static const String route = '/otp-verification';

  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _otpController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  static const int _resendSeconds = 30;
  int _remainingSeconds = _resendSeconds;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 24,
    ).chain(CurveTween(curve: Curves.easeInOutCubic)).animate(_shakeController);

    _shakeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _shakeController.reset();
      }
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _shakeController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _remainingSeconds = _resendSeconds);

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds == 0) {
        timer.cancel();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _verifyOtp() {
    final otp = _otpController.text.trim();
    if (otp.length == 5) {
      if (_formKey.currentState!.validate()) {
        // Do your OTP verification logic here
        context.pushName(AddFingerprint.route);
      }
    } else {
      _shakeController.forward(from: 0);
      context.showSnackBar('Please enter a valid 5-digit OTP');
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 64,
      textStyle: context.bodyMedium.copyWith(color: context.titleColor),
      decoration: BoxDecoration(
        color: context.inputBackground,
        border: Border.all(color: context.outline),
        borderRadius: BorderRadius.circular(12),
      ),
    );

    return Scaffold(
      appBar: buildNewAppBar(context, child: CustomAppBar()),
      body: Padding(
        padding: 16.px,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            32.s,
            Icon(
              TablerIcons.lock_access,
              size: 48,
              color: context.primaryColor,
            ),
            32.s,
            Text('Enter the 6-digit code', style: context.titleLarge.bold),
            4.s,
            Text(
              'We’ve sent an OTP to your registered number.',
              style: context.bodyMedium.k(context.secondaryContent),
              textAlign: TextAlign.center,
            ),
            32.s,
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                final offset = _shakeAnimation.value;
                return Transform.translate(
                  offset: Offset(offset, 0),
                  child: child,
                );
              },
              child: Form(
                key: _formKey,
                child: Pinput(
                  controller: _otpController,
                  length: 5,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: defaultPinTheme.copyWith(
                    decoration: defaultPinTheme.decoration!.copyWith(
                      border: Border.all(color: context.primaryColor),
                    ),
                  ),
                  validator: (value) => value != null && value.length == 5
                      ? null
                      : 'Enter 5 digits',
                  onCompleted: (_) => _verifyOtp(),
                ),
              ),
            ),
            32.s,
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _verifyOtp,
                child: const Text('Verify'),
              ),
            ),
            16.s,
            Text(
              _remainingSeconds == 0
                  ? 'Resend Code'
                  : 'Resend in $_remainingSeconds s',
              style: context.bodyMedium.bold.k(
                _remainingSeconds == 0
                    ? context.primaryColor
                    : context.secondaryContent,
              ),
            ).onTap(() {
              if (_remainingSeconds == 0) {
                _otpController.clear();
                _startResendTimer();

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('OTP resent')));

                // TODO: add API call to resend OTP
              }
            }),
          ],
        ),
      ),
    );
  }
}
