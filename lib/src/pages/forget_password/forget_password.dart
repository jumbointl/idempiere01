import 'package:flutter/material.dart';
import 'package:flutter_addons/flutter_addons.dart';
import 'package:monalisa_app_001/src/components/appbar_builder.dart';
import 'package:monalisa_app_001/src/components/primary_button.dart';
import 'package:monalisa_app_001/src/components/global_textfield.dart';
import 'package:monalisa_app_001/src/pages/change_pass/change_password.dart';

class ForgotPasswordScreen extends StatelessWidget {
  static const route = '/forgot-password';
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildNewAppBar(context, child: CustomAppBar()),
      backgroundColor: context.background,
      body: Padding(
        padding: 16.px,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            24.s,
            Center(
              child: Icon(
                Icons.lock_outline_rounded,
                size: 64,
                color: context.primaryColor,
              ),
            ),
            16.s,
            Center(
              child: Text(
                "Reset your password",
                style: context.titleMedium.bold,
              ),
            ),
            8.s,
            Center(
              child: Text(
                "Enter the email address associated with your account and we’ll send you a link to reset your password.",
                style: context.bodyMedium.k(context.secondaryContent),
              ),
            ),
            32.s,
            const _ForgotPasswordForm(),
          ],
        ),
      ),
    );
  }
}

class _ForgotPasswordForm extends StatefulWidget {
  const _ForgotPasswordForm();

  @override
  State<_ForgotPasswordForm> createState() => _ForgotPasswordFormState();
}

class _ForgotPasswordFormState extends State<_ForgotPasswordForm> {
  final _formKey = GlobalKey<FormState>();
  String email = '';

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          CustomTextField(
            hint: "Email Address",
            leading: const Icon(Icons.email_outlined),
            keyboardType: TextInputType.emailAddress,
            onChanged: (value) => email = value,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Email is required';
              if (!value.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          24.s,
          PrimaryButton(
            label: "Send Reset Link",
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                // TODO: Implement reset logic (API)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password reset link sent!')),
                );

                context.pushName(ChangePasswordScreen.route);
              }
            },
          ),
        ],
      ),
    );
  }
}
