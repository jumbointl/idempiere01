import 'package:flutter_addons/flutter_addons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/src/components/appbar_builder.dart';
import 'package:monalisa_app_001/src/components/primary_button.dart';
import 'package:monalisa_app_001/src/components/global_textfield.dart';
import 'package:monalisa_app_001/src/core/routes/route_export.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  static const String route = '/change-password';
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // Handle password change logic
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      LoginPage().launch(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildNewAppBar(context, child: CustomAppBar()),
      body: SingleChildScrollView(
        padding: 16.px,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              20.s,
              Text('Update your password', style: context.titleMedium.bold),
              4.s,
              Text(
                'Make sure your new password is strong and secure.',
                style: context.bodyMedium.k(context.secondaryContent),
              ),
              24.s,
              CustomTextField(
                label: 'Current Password',
                hint: 'Enter current password',
                obsecure: _obscureCurrent,
                controller: _currentPasswordController,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
                toggleVisibility: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
                leading: const Icon(Icons.lock_outline),
              ),
              16.s,
              CustomTextField(
                label: 'New Password',
                hint: 'Enter new password',
                obsecure: _obscureNew,
                controller: _newPasswordController,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  if (val.length < 6) return 'Too short';
                  return null;
                },
                toggleVisibility: () =>
                    setState(() => _obscureNew = !_obscureNew),
                leading: const Icon(Icons.lock),
              ),
              16.s,
              CustomTextField(
                label: 'Confirm Password',
                hint: 'Confirm new password',
                obsecure: _obscureConfirm,
                controller: _confirmPasswordController,
                validator: (val) {
                  if (val != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
                toggleVisibility: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                leading: const Icon(Icons.lock),
              ),
              32.s,
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  onPressed: _submit,
                  // icon: const Icon(Icons.check_circle_outline),
                  label: 'Update Password',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
