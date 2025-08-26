import 'package:flutter/material.dart';
import 'package:flutter_addons/flutter_addons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:monalisa_app_001/src/components/appbar_builder.dart';
import 'package:monalisa_app_001/src/core/utility/snack_bar.dart';

class QrScannerScreen extends StatefulWidget {
  static const String route = '/qr-scanner';
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isFlashOn = false;
  String? _errorMessage;

  void _onDetect(BarcodeCapture capture) {
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code != null) {
      //Navigator.pop(context, code);
      context.showSnackBar(code.toString());
    } else {
      setState(() {
        _errorMessage = 'Invalid QR code';
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.background,
      appBar: buildNewAppBar(
        context,
        child: Consumer(
          builder: (_, WidgetRef ref, __) {
            return CustomAppBar(
              title: 'Scan QR Code',
              onBackPressed: () {
                context.pop();
              },
            );
          },
        ),
      ),

      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            fit: BoxFit.cover,
            onDetect: _onDetect,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/qrCodeImage.png',
                width: 260.w,
                height: 260.h,
                fit: BoxFit.contain,
              ),
              32.s,
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(TablerIcons.line_scan, color: context.titleInverse),
                  5.s,
                  Text(
                    'Align the code within the frame',
                    style: context.bodyMedium.k(context.titleInverse),
                  ),
                ],
              ),
            ],
          ),
          if (_errorMessage != null)
            Positioned(
              bottom: 110.h,
              left: 24.w,
              right: 24.w,
              child: Center(
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.redAccent, fontSize: 14.sp),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),

      bottomNavigationBar: Container(
        height: 70.h,
        color: context.background,
        child: Center(
          child: IconButton(
            icon: Icon(
              _isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: context.primaryColor,
              size: 28.sp,
            ),
            onPressed: () {
              setState(() {
                _isFlashOn = !_isFlashOn;
                _controller.toggleTorch();
              });
            },
          ),
        ),
      ),
    );
  }
}
