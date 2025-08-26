import 'package:flutter/material.dart';
import 'package:flutter_addons/flutter_addons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:monalisa_app_001/src/components/appbar_builder.dart';
import 'package:monalisa_app_001/src/pages/create_pin/create_pin.dart';

class AddFingerprint extends StatelessWidget {
  static const String route = '/add_fingerprint';
  const AddFingerprint({super.key});

  @override
  Widget build(BuildContext context) {
    buildHeader() {
      return Column(
        children: [
          Text('Add Fingerprint', style: context.titleMedium),
          12.s,
          Text(
            'Set high level security for your\naccount by fingerprint lock',
            style: context.bodyMedium,
            textAlign: TextAlign.center,
          ),
          25.s,
        ],
      );
    }

    buildFinger() {
      return SizedBox(
        width: double.infinity,
        height: 600.h,
        child: Stack(
          children: [
            Positioned.fill(
              child: SvgPicture.asset(
                'assets/svgs/finger_bg.svg',
                fit: BoxFit.fill,
              ),
            ),
            Positioned(
              bottom: 42.h,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  SizedBox(height: 16.h),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        ///
                        context.pushName(CreatePinScreen.route);
                      },
                      borderRadius: BorderRadius.circular(100.r),
                      splashColor: context.primaryColor.withValues(
                        alpha: 0.3,
                      ), // Splash effect on icon only
                      child: Container(
                        margin: 4.m,
                        padding: 24.p,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: context.shadow.withValues(alpha: 0.2),
                              blurRadius: 10,
                              spreadRadius: 5,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: SvgPicture.asset(
                          'assets/svgs/fingerprint.svg',
                          height: 75.h,
                          width: 57.w,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  44.s,
                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        text: 'By set finger print you agree to our\n',
                        style: context.bodySmall,
                        children: [
                          TextSpan(
                            text: 'Terms and Conditions',
                            style: context.bodySmall.bold,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: buildNewAppBar(context, child: CustomAppBar()),

      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(child: buildHeader()),
          Expanded(child: buildFinger()),
        ],
      ),
    );
  }
}
