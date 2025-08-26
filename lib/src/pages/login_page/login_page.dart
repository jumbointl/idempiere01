import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_addons/flutter_addons.dart';
import 'package:monalisa_app_001/src/components/appbar_builder.dart';
import 'package:monalisa_app_001/src/components/primary_button.dart';
import 'package:monalisa_app_001/src/components/global_textfield.dart';
import 'package:monalisa_app_001/src/core/constants/app_constants.dart';
import 'package:monalisa_app_001/src/pages/forget_password/forget_password.dart';
import 'package:monalisa_app_001/src/pages/home_page/home_page.dart';
import '../signup_page/sign_up.dart';

class LoginPage extends ConsumerStatefulWidget {
  static const String route = '/login';
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      // Simulate successful login
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login successful'),
          backgroundColor: Colors.green,
        ),
      );
    }
    //auto launch
    context.pushName(HomePage.route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.background,
      appBar: buildNewAppBar(context, child: const CustomAppBar(title: '')),
      body: Padding(
        padding: 16.px,
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  20.s,
                  _buildHeader(context),
                  20.s,
                  Expanded(child: _buildForm(context)),
                  _buildSocialLogin(context),
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
        Text('Welcome to Swift', style: context.titleMedium),
        5.s,
        Text('Sign in to your account', style: context.titleSmall),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          CustomTextField(
            hint: 'Enter your email address',
            controller: _emailController,
            leading: Icon(Icons.email, color: context.primaryColor),
            validator: Validator.email,
          ),
          20.s,
          CustomTextField(
            hint: 'Enter your password',
            controller: _passwordController,
            obsecure: _obscurePassword,
            toggleVisibility: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
            leading: Icon(Icons.lock, color: context.primaryColor),
            validator: Validator.password,
          ),
          20.s,
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              style: TextButton.styleFrom(backgroundColor: context.background),
              onPressed: () => context.pushName(ForgotPasswordScreen.route),
              child: Text(
                'Forgot Password?',
                style: context.labelMedium.copyWith(
                  color: context.subtitleColor,
                ),
              ),
            ),
          ),
          16.s,
          PrimaryButton(
            label: 'Log In',
            color: context.primaryColor,
            textColor: context.titleInverse,
            onPressed: _submit,
          ),
          16.s,
          Wrap(
            children: [
              Text("Don't have an account? ", style: context.bodyMedium),
              Text(
                "Create one now",
                style: context.bodyMedium.copyWith(color: context.primaryColor),
              ).onTap(() => context.pushName(SignupPage.route)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLogin(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            kMargin.s,
            Text('Or continue with', style: context.bodySmall),
            kMargin.s,
            const Expanded(child: Divider()),
          ],
        ),
        kMargin.s,
        PrimaryButton(
          icon: "assets/images/Google.png",
          label: 'Sign in with Google',
          color: context.secondaryButton,
          textColor: context.bodyTextColor,
          borderColor: context.outline,
          onPressed: () {
            context.pushName(HomePage.route); // Replace with Google Sign-In
          },
        ),
        48.s,
      ],
    );
  }
}
