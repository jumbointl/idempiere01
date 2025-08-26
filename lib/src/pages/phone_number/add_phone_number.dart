import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter_addons/flutter_addons.dart';
import 'package:flutter_svg/svg.dart';
import 'package:monalisa_app_001/src/core/resource/app_resources.dart';
import 'package:monalisa_app_001/src/components/appbar_builder.dart';
import 'package:monalisa_app_001/src/components/primary_button.dart';
import 'package:monalisa_app_001/src/core/constants/app_constants.dart';
import 'package:monalisa_app_001/src/pages/otp_verification/pin_verification.dart';

class PhoneInputScreen extends StatefulWidget {
  static const String route = '/phone';
  const PhoneInputScreen({super.key});

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  Country _selectedCountry = Country(
    phoneCode: '880',
    countryCode: 'BD',
    e164Sc: 0,
    geographic: true,
    level: 1,
    name: 'Bangladesh',
    example: '01812345678',
    displayName: 'Bangladesh',
    displayNameNoCountryCode: 'BD',
    e164Key: '',
  );

  final TextEditingController _controller = TextEditingController();

  void _showCountryPicker() {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      countryListTheme: CountryListThemeData(
        flagSize: 25,
        textStyle: TextStyle(fontSize: 16.sp),
        padding: EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(kRadius),
        //bottomSheetHeight: 500.h,
        searchTextStyle: TextStyle(fontSize: 14.sp),
      ),
      onSelect: (Country country) {
        setState(() => _selectedCountry = country);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    buildHeader(BuildContext context) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: kMargin.h),
          Text("Number Verification", style: context.titleMedium),
          SizedBox(height: kMargin.h),
          SvgPicture.asset(AssetSvgs.smartphone, width: 100.w, height: 120.h),
          SizedBox(height: kMargin.h),
          Text(
            "You will receive a 4 digit code\nto verify next",
            style: context.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Scaffold(
      appBar: buildNewAppBar(context, child: CustomAppBar()),
      body: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            buildHeader(context),
            SizedBox(height: 20.h),
            _buildPhoneInput(context),
            SizedBox(height: 30.h),
            PrimaryButton(
              label: 'Continue',
              onPressed: () {
                final fullPhone =
                    '+${_selectedCountry.phoneCode}${_controller.text}';
                debugPrint('Phone: $fullPhone');
                context.pushName(OtpVerificationScreen.route);
              },
            ),
          ],
        ),
      ),
    );
  }

  TextFormField _buildPhoneInput(BuildContext context) {
    return TextFormField(
      controller: _controller,
      keyboardType: TextInputType.phone,
      style: context.titleSmall,
      validator: Validator.phone,
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadius),
          borderSide: BorderSide(color: context.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadius),
          borderSide: BorderSide(color: context.outline),
        ),
        filled: true,
        fillColor: context.cardBackground,
        prefixIcon: GestureDetector(
          onTap: _showCountryPicker,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: ClipOval(
                    child: Container(
                      color: context.background, // Circle background
                      alignment: Alignment.center,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _selectedCountry.flagEmoji,
                          style: context.titleSmall,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Container(height: 20.h, width: 1, color: context.primaryColor),
              ],
            ),
          ),
        ),
        prefixIconConstraints: BoxConstraints(minWidth: 25.w),
        hintText: '0198 367 8908',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      ),
    );
  }
}
