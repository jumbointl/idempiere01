import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:monalisa_app_001/src/components/appbar_builder.dart';
import 'package:monalisa_app_001/src/components/global_textfield.dart';
import 'package:monalisa_app_001/src/components/primary_button.dart';
import 'package:flutter_addons/flutter_addons.dart';
import 'package:monalisa_app_001/src/core/utility/snack_bar.dart';
import 'package:monalisa_app_001/src/data/models/user_model.dart';

class EditAccountScreen extends StatefulWidget {
  static const String route = '/edit-account';

  const EditAccountScreen({super.key});

  @override
  State<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _dobController;
  late final TextEditingController _addressController;

  String _gender = 'Male';
  String _country = 'USA';

  final List<String> genderOptions = ['Male', 'Female', 'Other'];
  final List<String> countryOptions = ['USA', 'Canada', 'UK', 'Bangladesh'];

  @override
  void initState() {
    _nameController = TextEditingController(text: user.name);
    _emailController = TextEditingController(text: user.email);
    _phoneController = TextEditingController(text: user.phone);
    _dobController = TextEditingController(text: user.dob);
    _addressController = TextEditingController(text: user.address);
    _gender = user.gender;
    _country = user.country;
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      context.showSnackBar("Profile updated successfully");
      Navigator.pop(context);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse('1990-01-01') ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _dobController.text = '${picked.month}/${picked.day}/${picked.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.background,
      appBar: buildNewAppBar(
        context,
        child: CustomAppBar(title: 'Edit account Details'),
      ),

      body: Padding(
        padding: 16.px,
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              32.s,
              Text('Full Name', style: context.bodySmall),
              6.s,
              CustomTextField(
                hint: 'Enter your full name',
                controller: _nameController,
                leading: Icon(TablerIcons.user, color: context.primaryColor),
                focusColor: context.outline,
                validator: Validator.required,
              ),
              16.s,

              Text('Email Address', style: context.bodySmall),
              6.s,
              CustomTextField(
                hint: 'Enter your email address',
                controller: _emailController,
                leading: Icon(TablerIcons.mail, color: context.primaryColor),
                focusColor: context.outline,
                validator: Validator.email,
              ),
              16.s,

              Text('Phone Number', style: context.bodySmall),
              6.s,
              CustomTextField(
                hint: 'Enter your phone number',
                controller: _phoneController,
                leading: Icon(TablerIcons.phone, color: context.primaryColor),
                focusColor: context.outline,
                validator: Validator.required,
              ),
              16.s,

              Text('Date of Birth', style: context.bodySmall),
              6.s,
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: CustomTextField(
                    hint: 'Select your date of birth',
                    controller: _dobController,
                    leading: Icon(
                      TablerIcons.calendar_event,
                      color: context.primaryColor,
                    ),
                    focusColor: context.outline,
                    validator: Validator.required,
                  ),
                ),
              ),
              16.s,

              Text('Gender', style: context.bodySmall),
              6.s,
              CustomDropdownFormField(
                value: _gender,
                items: genderOptions,
                hint: 'Gender',
                leading: Icon(
                  TablerIcons.gender_bigender,
                  color: context.primaryColor,
                ),
                onChanged: (value) => setState(() => _gender = value ?? 'Male'),
              ),
              16.s,

              Text('Address', style: context.bodySmall),
              6.s,
              CustomTextField(
                hint: 'Enter your address',
                controller: _addressController,
                leading: Icon(TablerIcons.map_pin, color: context.primaryColor),
                focusColor: context.outline,
                validator: Validator.required,
              ),
              16.s,

              Text('Country', style: context.bodySmall),
              6.s,
              CustomDropdownFormField(
                value: _country,
                items: countryOptions,
                hint: 'Select a country',
                leading: Icon(TablerIcons.world, color: context.primaryColor),
                onChanged: (value) => setState(() => _country = value ?? 'USA'),
              ),
              32.s,
              PrimaryButton(
                label: 'Save Changes',
                color: context.primaryColor,
                onPressed: _saveProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
