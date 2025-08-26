// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_addons/flutter_addons.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:monalisa_app_001/src/core/constants/app_constants.dart';

InputBorder flatBorder(BuildContext context, {Color? color}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(kRadius.r),
    borderSide: BorderSide(color: color ?? context.outline, width: 1),
  );
}

class CustomTextField extends StatelessWidget {
  final String hint;
  final String? label;
  final bool obsecure;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final Function()? toggleVisibility;
  final Widget? leading;
  final Color? focusColor;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const CustomTextField({
    super.key,
    required this.hint,
    this.label = '',
    this.obsecure = false,
    this.controller,
    this.validator,
    this.toggleVisibility,
    this.leading,
    this.focusColor,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      style: context.bodyMedium,
      controller: controller,
      obscureText: obsecure,
      validator: validator,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        label: label != null && label!.isNotEmpty
            ? Text(
                label!,
                style: context.labelMedium.copyWith(
                  color: context.secondaryContent,
                ),
              )
            : null,
        border: flatBorder(context, color: context.outline),
        enabledBorder: flatBorder(context, color: context.outline),
        focusedBorder: flatBorder(context, color: Colors.green),
        prefixIcon: leading,
        contentPadding: kPadding.p,
        filled: true,
        fillColor: context.inputBackground,
        hintText: hint,

        hintStyle: context.bodyMedium,
        suffixIcon: toggleVisibility != null
            ? IconButton(
                icon: Icon(
                  obsecure ? TablerIcons.eye : TablerIcons.eye_off,
                  color: context.primaryColor,
                ),
                onPressed: toggleVisibility,
              )
            : null,
      ),
    );
  }
}

class CustomDropdownFormField extends StatelessWidget {
  final String? value;
  final List<String> items;
  final String? label;
  final String? hint;
  final Widget? leading;
  final ValueChanged<String?>? onChanged;
  final FormFieldValidator<String>? validator;

  const CustomDropdownFormField({
    super.key,
    required this.value,
    required this.items,
    this.label,
    this.hint,
    this.leading,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      validator: validator,
      onChanged: onChanged,
      style: context.bodyMedium,
      decoration: InputDecoration(
        label: label != null && label!.isNotEmpty
            ? Text(
                label!,
                style: context.labelMedium.copyWith(
                  color: context.secondaryContent,
                ),
              )
            : null,
        border: flatBorder(context, color: context.outline),
        enabledBorder: flatBorder(context, color: context.outline),
        focusedBorder: flatBorder(context, color: Colors.green),
        prefixIcon: leading,
        contentPadding: kPadding.p,
        filled: true,
        fillColor: context.inputBackground,
        hintText: hint,
        hintStyle: context.bodyMedium,
      ),
      items: items.map((country) {
        return DropdownMenuItem<String>(
          value: country,
          child: Text(country, style: context.bodyMedium),
        );
      }).toList(),
    );
  }
}
