import 'package:flutter/material.dart';
import 'package:flutter_addons/flutter_addons.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:pinput/pinput.dart';
import 'package:monalisa_app_001/src/components/appbar_builder.dart';
import 'package:monalisa_app_001/src/pages/success_page/success_page.dart';

class CreatePinScreen extends StatefulWidget {
  static const String route = '/createpin';

  const CreatePinScreen({super.key});

  @override
  State<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isConfirming = false;
  String? _initialPin;

  void _onCompleted(String pin) {
    if (_isConfirming) {
      if (_initialPin == pin) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('PIN set successfully')));
        // Here you would typically save the PIN securely
        _reset();
        Future.microtask(() {
          if (context.mounted) {
            // ignore: use_build_context_synchronously
            SuccessPage().launch(context);
          }
        });
      } else if (pin.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('PIN cannot be empty')));
        _reset();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('PINs do not match')));
        _reset();
      }
    } else {
      setState(() {
        _initialPin = pin;
        _isConfirming = true;
      });
    }
  }

  void _reset() {
    _pinController.clear();
    _confirmController.clear();
    setState(() {
      _isConfirming = false;
      _initialPin = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 64,
      textStyle: context.bodyMedium.bold,
      decoration: BoxDecoration(
        color: context.inputBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.outline),
      ),
    );

    return Scaffold(
      appBar: buildNewAppBar(
        context,
        child: CustomAppBar(
          onBackPressed: _isConfirming ? _reset : () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            32.s,
            Icon(TablerIcons.lock_pin, size: 64, color: context.primaryColor),
            32.s,
            Text(
              _isConfirming ? "Confirm your PIN" : "Set a new PIN",
              style: context.titleMedium.bold,
            ),
            8.s,
            Text(
              "This PIN will be used to access your wallet securely.",
              style: context.bodyMedium.k(context.secondaryContent),
              textAlign: TextAlign.center,
            ),
            32.s,
            Pinput(
              length: 4,
              obscureText: true,
              controller: _isConfirming ? _confirmController : _pinController,
              defaultPinTheme: defaultPinTheme,
              focusedPinTheme: defaultPinTheme.copyWith(
                decoration: defaultPinTheme.decoration!.copyWith(
                  border: Border.all(color: context.primaryColor),
                ),
              ),
              onCompleted: _onCompleted,
            ),
            24.s,
            // if (_isConfirming)
            //   TextButton(
            //     onPressed: _reset,
            //     child: Text("Back", style: context.bodyMedium.bold),
            //   ),
          ],
        ),
      ),
    );
  }
}
