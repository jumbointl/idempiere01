import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_addons/flutter_addons.dart';
import 'package:monalisa_app_001/src/components/appbar_builder.dart';
import 'package:monalisa_app_001/src/components/primary_button.dart';
import 'package:monalisa_app_001/src/components/global_textfield.dart';
import 'package:monalisa_app_001/src/core/constants/app_constants.dart';
import 'package:monalisa_app_001/src/pages/login_page/login_page.dart';
import 'package:monalisa_app_001/src/pages/phone_number/add_phone_number.dart';

class SignupPage extends ConsumerStatefulWidget {
  static const String route = '/signup';
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      // Proceed to next step
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully'),
          backgroundColor: Colors.green,
        ),
      );
      context.pushName(PhoneInputScreen.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.background,
      appBar: buildNewAppBar(context, child: const CustomAppBar()),
      body: Padding(
        padding: kPadding.px,
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  Expanded(child: _buildForm(context)),
                  _buildSocialSignup(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        kMargin.s,
        Text("Create Your Account", style: context.titleMedium),
        5.s,
        Text("Sign up to get started", style: context.titleSmall),
        kMargin.s,
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        spacing: 20.h,
        children: [
          CustomTextField(
            controller: _nameController,
            hint: "Full Name",
            leading: Icon(Icons.person, color: context.primaryColor),
            validator: (val) => Validator.required(val, fieldName: 'Name'),
          ),
          CustomTextField(
            controller: _emailController,
            hint: "Email Address",
            leading: Icon(Icons.email, color: context.primaryColor),
            validator: Validator.email,
          ),
          CustomTextField(
            controller: _passwordController,
            hint: "Password",
            obsecure: _obscurePassword,
            toggleVisibility: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            leading: Icon(Icons.lock, color: context.primaryColor),
            validator: Validator.password,
          ),
          CustomTextField(
            controller: _confirmPasswordController,
            hint: "Confirm Password",
            obsecure: _obscureConfirm,
            toggleVisibility: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
            leading: Icon(Icons.lock, color: context.primaryColor),
            validator: (v) => Validator.match(
              v,
              _passwordController.text,
              fieldName: "Passwords",
            ),
          ),
          24.s,
          PrimaryButton(
            label: "Sign Up",
            color: context.primaryColor,
            textColor: context.titleInverse,
            onPressed: _submit,
          ),
          16.s,
          Wrap(
            children: [
              Text("Already have an account?", style: context.bodyMedium),
              Text(
                " Login",
                style: context.bodyMedium.copyWith(color: context.primaryColor),
              ).onTap(() => context.pushName(LoginPage.route)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialSignup(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            kMargin.s,
            Text('Or sign up using', style: context.bodySmall),
            kMargin.s,
            const Expanded(child: Divider()),
          ],
        ),
        kMargin.s,
        PrimaryButton(
          label: 'Continue with Google',
          icon: "assets/images/Google.png",
          color: context.secondaryButton,
          textColor: context.bodyTextColor,
          borderColor: context.outline,
          onPressed: () {
            // Handle Google Sign Up
            context.pushName(PhoneInputScreen.route);
          },
        ),
        48.s,
      ],
    );
  }
}
