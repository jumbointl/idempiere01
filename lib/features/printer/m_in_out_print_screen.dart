import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/features/printer/printer_setup_screen.dart';
import 'package:monalisapy_features/actions/monalisa_action.dart';
import 'package:monalisapy_features/printer/models/mo_printer.dart';

import '../../config/router/app_router.dart';
import '../../config/theme/app_theme.dart';
import '../m_inout/domain/entities/m_in_out.dart';
import '../m_inout/printables/m_in_out_printable.dart';
import '../products/common/messages_dialog.dart';
import '../products/common/widget_utils.dart';
import '../products/presentation/providers/common_provider.dart';
import '../shared/data/messages.dart';
import 'cups_printer.dart';

class MInOutPrintScreen extends PrinterSetupScreen {
  MInOutPrintScreen({
    super.key,
    required MInOut mInOut,
    required int oldAction,
  }) : super(
          printable: MInOutPrintable(mInOut),
          oldAction: MonalisaAction.fromInt(oldAction),
          loadLogoBytes: () => imageLogo,
          onOpenMoPrinterEditor: _openMoPrinterEditor,
          onOpenLocatorSentenceEditor: _openLocatorSentenceEditor,
        );

  @override
  Widget getPrintPanel(WidgetRef ref, BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: compactElevatedButton(
            label: Messages.SHARE,
            backgroundColor: themeColorPrimary,
            onPressed: () async {
              await printPdf(ref, context, direct: false);
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: compactElevatedButton(
            label: Messages.PRINT,
            backgroundColor: (ref.read(lastPrinterProvider.notifier).state !=
                    null
                ? Colors.green
                : themeColorPrimary),
            onPressed: () async {
              printFromCurrentSetup(ref, context, dataToPrint);
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: compactElevatedButton(
            label: 'PREVIEW',
            backgroundColor: themeColorPrimary,
            onPressed: () async {
              showWarningCenterToast(context, Messages.NOT_IMPLEMENTED_YET);
            },
          ),
        ),
      ],
    );
  }
}

Future<MOPrinter?> _openMoPrinterEditor({
  required BuildContext context,
  required WidgetRef ref,
  required FocusNode focusNode,
  MOPrinter? initial,
}) {
  return context.push<MOPrinter>(
    AppRouter.PAGE_MO_PRINTER_EDITOR,
    extra: {
      'focusNode': focusNode,
      'initial': initial,
    },
  );
}

Future<String?> _openLocatorSentenceEditor({
  required BuildContext context,
  required FocusNode focusNode,
  required String initialSentence,
}) {
  return context.push<String>(
    AppRouter.PAGE_LOCATOR_SENTENCE_EDITOR,
    extra: {
      'sentence': initialSentence,
      'focusNode': focusNode,
    },
  );
}
