import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../config/router/app_router.dart';
import '../../../config/theme/app_theme.dart';
import '../../shared/data/messages.dart';
import '../presentation/providers/product_provider_common.dart';
import 'input_data_processor.dart';

abstract class CommonConsumerState<T extends ConsumerStatefulWidget>
    extends ConsumerState<T> implements InputDataProcessor {
  // --------- Common theme / text styles ----------
  double? get fontSizeTitle => themeFontSizeTitle;
  double? get fontSizeLarge => themeFontSizeLarge;
  double? get fontSizeMedium => themeFontSizeNormal;
  double? get fontSizeSmall => themeFontSizeSmall;

  Color? get fontBackgroundColor => Colors.white;
  Color? get fontForegroundColor => Colors.black;

  Color? get backgroundColor => Colors.white;
  Color? get foregroundColor => Colors.black;

  Color? get hintTextColor => Colors.purple;
  Color? get resultColor => Colors.purple;
  Color? get borderColor => Colors.black;
  bool isPopping = false;
  late final TextStyle textStyleTitle =
  TextStyle(fontSize: fontSizeTitle, color: fontForegroundColor);
  late final TextStyle textStyleTitleMore20C =
  TextStyle(fontSize: 13, color: fontForegroundColor);
  late final TextStyle textStyleLarge =
  TextStyle(fontSize: fontSizeLarge, color: fontForegroundColor);
  late final TextStyle textStyleLargeBold = TextStyle(
    fontSize: fontSizeLarge,
    color: fontForegroundColor,
    fontWeight: FontWeight.bold,
  );
  late final TextStyle textStyleMedium =
  TextStyle(fontSize: fontSizeMedium, color: fontForegroundColor);
  late final TextStyle textStyleMediumBold = TextStyle(
    fontSize: fontSizeMedium,
    color: fontForegroundColor,
    fontWeight: FontWeight.bold,
  );
  late final TextStyle textStyleSmall =
  TextStyle(fontSize: fontSizeSmall, color: fontForegroundColor);
  late final TextStyle textStyleSmallBold = TextStyle(
    fontSize: fontSizeSmall,
    color: fontForegroundColor,
    fontWeight: FontWeight.bold,
  );
  late final TextStyle textStyleBold =
  TextStyle(color: fontForegroundColor, fontWeight: FontWeight.bold);

  // --------- Common helpers ----------
  // English: Unfocus the current input
  void unfocus() => FocusScope.of(context).unfocus();

  // English: Navigate to home safely
  void goHome() {
    if(isPopping) return ;
    isPopping = true;
    unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      context.go(AppRouter.PAGE_HOME);
    });
  }

  // English: Centralized scanning state helpers
  void startScanning() {
    ref.read(isScanningProvider.notifier).state = true;
  }

  void stopScanning() {
    ref.read(isScanningProvider.notifier).state = false;
  }

  // --------- UI common: Result bottom sheet ----------
  Future<void> showResultBottomSheetMessages({
    required WidgetRef ref,
    required String title,
    required String message,
    required bool success,
    required Future<void> Function() onOk,
  }) async {
    // English: Keep background neutral for readability
    final accent = success ? Colors.green : Colors.red;

    await showModalBottomSheet<void>(
      isDismissible: false,
      enableDrag: false,
      context: ref.context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return FractionallySizedBox(
          heightFactor: 0.7,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent, width: 2),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      success ? Icons.check_circle : Icons.error,
                      color: accent,
                      size: 54,
                    ),
                    const SizedBox(height: 10),
                    if (title.isNotEmpty)
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: fontSizeTitle,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    if (title.isNotEmpty) const SizedBox(height: 8),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: fontSizeLarge,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(ctx).pop();
                          await onOk();
                        },
                        child: const Text('OK'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // --------- UI common: Confirmation bottom sheet ----------
  Future<bool?> openBottomSheetConfirmationDialog({
    required WidgetRef ref,
    required String title,
    required String message,
    IconData iconData = Symbols.live_help,
    Color? iconColor = Colors.amberAccent,
  }) async {
    // English: Return bool? (null = cancelled, true = confirmed)
    final result = await showModalBottomSheet<bool?>(
      isScrollControlled: true,
      context: ref.context,
      builder: (BuildContext ctx) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 20),
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    spacing: 5,
                    children: [
                      Icon(iconData, size: 60, color: iconColor),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: fontSizeLarge,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: fontSizeLarge,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        spacing: 10,
                        children: [
                          Expanded(
                            child: TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.red,
                              ),
                              onPressed: () {
                                Navigator.pop(ctx, null);
                              },
                              child: Text(Messages.CANCEL),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.green,
                              ),
                              onPressed: () {
                                Navigator.pop(ctx, true);
                              },
                              child: Text(Messages.CONFIRM),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    // English: Ensure provider state is reset after dialog closes
    ref.read(isDialogShowedProvider.notifier).state = false;

    return result;
  }

  // --------- Short wrappers to unify usage ----------
  // English: Standard confirm helper
  Future<bool> confirmAction({
    required String title,
    required String message,
  }) async {
    final result = await openBottomSheetConfirmationDialog(
      ref: ref,
      title: title,
      message: message,
    );
    return result == true;
  }

  // English: Standard error sheet
  Future<void> showErrorSheet(String message, {String? title}) {
    return showResultBottomSheetMessages(
      ref: ref,
      title: title ?? Messages.ERROR,
      message: message,
      success: false,
      onOk: () async {},
    );
  }

  // English: Standard success sheet
  Future<void> showSuccessSheet(String message, {String? title}) {
    return showResultBottomSheetMessages(
      ref: ref,
      title: title ?? Messages.SUCCESS,
      message: message,
      success: true,
      onOk: () async {},
    );
  }
}
