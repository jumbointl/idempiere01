import 'package:flutter/material.dart';
import 'package:monalisa_app_001/config/config.dart';

class CustomFilledButton extends StatelessWidget {
  final void Function()? onPressed;
  final String label;
  final Color? buttonColor;
  final Icon? icon;
  final Color? labelColor;
  final bool isPosting;
  final bool expand;
  final bool small;

  const CustomFilledButton({
    super.key,
    this.onPressed,
    required this.label,
    this.buttonColor,
    this.icon,
    this.labelColor,
    this.isPosting = false,
    this.expand = false,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: SizedBox(
        height: small ? 30 : 40,
        width: expand ? double.infinity : null,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
              backgroundColor: buttonColor,
              disabledBackgroundColor: Colors.grey,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(themeBorderRadius))),
          onPressed: onPressed,
          icon: icon != null
              ? isPosting
                  ? _buildLoadingIndicator()
                  : _buildIcon()
              : null,
          label:
              Text(label, style: TextStyle(color: labelColor ?? Colors.white)),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(
        color: Colors.white,
        strokeWidth: 2,
      ),
    );
  }

  Widget _buildIcon() {
    return Icon(icon!.icon, color: labelColor ?? Colors.white);
  }
}
