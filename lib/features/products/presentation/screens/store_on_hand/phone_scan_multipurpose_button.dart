
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_addons/flutter_addons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/config/config.dart';

import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../providers/product_provider_common.dart';
import '../../providers/products_scan_notifier.dart';
class PhoneScanMultipurposeButton extends ConsumerStatefulWidget {
  final ProductsScanNotifier notifier;

  String scannedData = "";
  PhoneScanMultipurposeButton(this.notifier,{super.key});
  void handleResult(WidgetRef ref, String data,int actionTypeInt) {
    if (data.isNotEmpty) {
      switch (actionTypeInt) {
        case Memory.ACTION_GET_LOCATOR_TO_VALUE:
          Memory.awesomeDialog?.dismiss();
          notifier.setLocatorToValue(data);
          break;
        case Memory.ACTION_GET_LOCATOR_FROM_VALUE:
          Memory.awesomeDialog?.dismiss();
          notifier.setLocatorFromValue(data);
          break;
      }
      scannedData = "";
    }
  }
  @override
  ConsumerState<PhoneScanMultipurposeButton> createState() => _PhoneScanMultipurposeButtonState();
}


class _PhoneScanMultipurposeButtonState extends ConsumerState<PhoneScanMultipurposeButton> {
  final FocusNode _focusNode = FocusNode();
  int scannedTimes = 0;
  @override
  initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    _focusNode.requestFocus();
  }
  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) async {

    print('--x--event.character ${event.character}');
    print('--x--event.logicalKey ${event.logicalKey.keyLabel}');
    print('--x--event.keyName ${event.logicalKey.keyId}');
    print('--x--scannedData ${widget.scannedData}');

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      widget.handleResult(ref, widget.scannedData,ref.read(actionScanProvider.notifier).state);
      widget.scannedData ="";
      return;
    }

    if (event.character != null && event.character!.isNotEmpty) {
      widget.scannedData += event.character!;
    }

  }


  @override
  Widget build(BuildContext context) {

    final usePhoneCamera = ref.watch(usePhoneCameraToScanProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {

      if (mounted) {

        if (ref.read(isScanningProvider.notifier).state) {
          _focusNode.unfocus();
        } else {
          _focusNode.requestFocus();
          if (!_focusNode.hasFocus) {
            Future.delayed(const Duration(milliseconds: 100), () {
              _focusNode.requestFocus();

            });
          }
        }
      }
    });
    return KeyboardListener(
      focusNode:_focusNode,
      onKeyEvent: ref.read(isScanningProvider) ? null : _handleKeyEvent,
      child: TextButton(
        onPressed: () {
          if(usePhoneCamera.state){
            usePhoneCamera.update((state) => false);
            _focusNode.requestFocus();
          } else {
            _focusNode.unfocus();
            usePhoneCamera.update((state) => true);
          }
          setState(() {});

        },
        style: TextButton.styleFrom(
          backgroundColor: usePhoneCamera.state ? Colors.cyan : themeColorPrimary,
          //padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
        ),
        child: Text(usePhoneCamera.state ? Messages.CAMERA : Messages.SCAN_SHORT, style: context.bodySmall.k(context.titleInverse)),
      ),
      /*child: GestureDetector(
        onTap: (){},
        child: Container(
          height: 40,
          width: double.infinity,
          decoration: BoxDecoration(
            color: _focusNode.hasFocus ? themeColorPrimary : Colors.grey,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text( Messages.SCAN,
                style: context.bodySmall.k(context.titleInverse)
              ),
            ],
          ),
        ),
      ),*/
    );
  }
}
