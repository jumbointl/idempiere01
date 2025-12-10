import 'package:flutter/material.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/movement_and_lines.dart';

import '../../../../../../config/theme/app_theme.dart';
import '../../../../../shared/data/messages.dart';

double? get fontSizeTitle =>themeFontSizeTitle;
double? get fontSizeLarge =>themeFontSizeLarge;
double? get fontSizeMedium=>themeFontSizeNormal;
double? get fontSizeSmall=>themeFontSizeSmall;
Color? get fontBackgroundColor=>Colors.white;
Color? get fontForegroundColor=>Colors.black;
Color? get backgroundColor=>Colors.white;
Color? get foregroundColor=>Colors.black;
Color? get hintTextColor=>Colors.purple;
Color? get resultColor=>Colors.purple;
Color? get borderColor=>Colors.black;
int get qtyOfDataToAllowScroll => 2;
TextStyle textStyleTitle = TextStyle(fontSize: fontSizeTitle,
    color: fontForegroundColor);
TextStyle textStyleTitleMore20C = TextStyle(fontSize: 13,
    color: fontForegroundColor);
TextStyle textStyleLarge = TextStyle(fontSize: fontSizeLarge,
    color: fontForegroundColor);
TextStyle textStyleLargeBold = TextStyle(fontSize: fontSizeLarge,
    color: fontForegroundColor, fontWeight: FontWeight.bold);
TextStyle textStyleMedium = TextStyle(fontSize: fontSizeMedium,
    color: fontForegroundColor);
TextStyle textStyleMediumBold = TextStyle(fontSize: fontSizeMedium,
    color: fontForegroundColor, fontWeight: FontWeight.bold);
TextStyle textStyleSmall = TextStyle(fontSize: fontSizeSmall,
    color: fontForegroundColor);
TextStyle textStyleSmallBold = TextStyle(fontSize: fontSizeSmall,
    color: fontForegroundColor, fontWeight: FontWeight.bold);
TextStyle textStyleBold = TextStyle(
    color: fontForegroundColor, fontWeight: FontWeight.bold);


Widget movementAppBarTitle({
  required VoidCallback onBack,
  MovementAndLines? movementAndLines,
  showBackButton = true,
  String subtitle = '',
}) {
  TextStyle styleMain = TextStyle(fontSize: themeFontSizeLarge);
  final m = movementAndLines;
  if(subtitle.isEmpty) subtitle = '${m?.id ?? ''}   ${m?.docStatus?.id ?? ''}';


  // Caso: ya hay movimiento
  if (m?.hasMovement ?? false) {
    styleMain = m!.documentNo != null && m.documentNo!.length > 20
        ? textStyleTitleMore20C
        : textStyleLarge;

    return Row(
      children: [
        if(showBackButton)IconButton(
          icon: const Icon(Icons.arrow_back),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
          onPressed: onBack,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                m.documentNo ?? '',
                style: styleMain,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              Text(
                subtitle,
                style: textStyleSmallBold,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Caso: creando movimiento / sin movimiento todavía
  return Row(
    children: [
      if(showBackButton) IconButton(
        icon: const Icon(Icons.arrow_back),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minWidth: 32,
          minHeight: 32,
        ),
        onPressed: onBack,
      ),
      const SizedBox(width: 4),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              Messages.MOVEMENT_CREATE,
              style: styleMain,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            Text(
              '${m?.id ?? ''}   ${m?.docStatus?.id ?? ''}',
              style: textStyleSmallBold,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ],
  );
}


Widget commonAppBarTitle({
  required VoidCallback onBack,
  showBackButton = true,
  String subtitle = '',
  String title ='',
}) {
  TextStyle styleMain = TextStyle(fontSize: themeFontSizeLarge);
  styleMain = title.length > 20
      ? textStyleTitleMore20C
      : textStyleLarge;
  return Row(
    children: [
      if(showBackButton)IconButton(
        icon: const Icon(Icons.arrow_back),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minWidth: 32,
          minHeight: 32,
        ),
        onPressed: onBack,
      ),
      const SizedBox(width: 4),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: styleMain,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            if(subtitle.isNotEmpty) Text(
              subtitle,
              style: textStyleSmallBold,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ],
  );

}
