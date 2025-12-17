import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../config/theme/app_theme.dart';
import '../../shared/data/messages.dart';
import '../presentation/providers/product_provider_common.dart';
import 'input_data_processor.dart';

abstract class CommonConsumerState<T extends ConsumerStatefulWidget>
    extends ConsumerState<T> implements InputDataProcessor {
  // --------- Tema / estilos comunes ----------
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


  // --------- UI común: BottomSheet mensajes ----------
  Future<void> showResultBottomSheetMessages({
    required WidgetRef ref,
    required String title,
    required String message,
    required bool success,
    required Future<void> Function() onOk,
  }) async {
    final color = success ? Colors.green : Colors.red;

    await showModalBottomSheet(
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
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SingleChildScrollView(
                child: Column(
                  spacing: 10,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      success ? Icons.check_circle : Icons.error,
                      color: success ? Colors.green : Colors.red,
                      size: 50,
                    ),
                    if (title.isNotEmpty)
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: themeFontSizeTitle,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (title.isNotEmpty) const SizedBox(height: 8),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: themeFontSizeLarge,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
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

  Future<String?> openBottomSheetConfirmationDialog(

      {required  WidgetRef ref, required String title ,
        required String message,
        IconData iconData = Symbols.live_help,
        Color? iconColor = Colors.amberAccent,
      }

      ) async {


    final result = await showModalBottomSheet<String?>(
      isScrollControlled: true,
      context: ref.context,
      builder: (BuildContext context) {


        return Consumer(
          builder: (context, ref, child) {
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
                          Icon(iconData,size: 60,color: iconColor),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: fontSizeLarge,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                          Text(
                            message,
                            style: TextStyle(
                              fontSize: fontSizeLarge,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
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
                                  onPressed: ()
                                  {
                                    Navigator.pop(context, null);
                                  },
                                  child: Text(Messages.CANCEL),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.green,
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context, true);
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
      },
    );

    ref.read(isDialogShowedProvider.notifier).state = false;
    return result;
  }

}

