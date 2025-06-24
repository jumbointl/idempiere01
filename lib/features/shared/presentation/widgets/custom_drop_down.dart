import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/config/config.dart';

import '../../../auth/domain/entities/client.dart';
import '../../../auth/domain/entities/organization.dart';
import '../../../auth/domain/entities/role.dart';
import '../../../auth/domain/entities/warehouse.dart';

class CustomDropDown<T> extends ConsumerWidget {
  final String label;
  final T? value;
  final List<T> options;
  final ValueChanged<T?> onChanged;
  final bool expand;

  const CustomDropDown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: themeBorderRadius / 2),
          child: Text(label, style: TextStyle(fontSize: themeFontSizeSmall)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          height: 40,
          width: expand ? double.infinity : null,
          decoration: BoxDecoration(
            color: themeBackgroundColorLight,
            border: Border.all(color: themeColorGrayLight),
            borderRadius: BorderRadius.circular(themeBorderRadius),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              onChanged: onChanged,
              items: options
                  .map((option) => DropdownMenuItem(
                        value: option,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                              maxWidth: size.width - 80, maxHeight: 40),
                          child: Text(
                            option is Client
                                ? option.name
                                : option is Role
                                    ? option.name
                                    : option is Organization
                                        ? option.name
                                        : (option as Warehouse).name,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: themeFontSizeNormal,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}
