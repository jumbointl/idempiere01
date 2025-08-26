import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_addons/flutter_addons.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart' show Svg;
import 'package:monalisa_app_001/src/core/resource/app_resources.dart';
import 'package:monalisa_app_001/src/components/appbar_builder.dart';
import 'package:monalisa_app_001/src/components/primary_button.dart';
import 'package:monalisa_app_001/src/components/global_textfield.dart';

class AddCardScreen extends ConsumerWidget {
  static const route = '/add-card';
  const AddCardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: buildNewAppBar(context, child: CustomAppBar(title: 'Add Card')),
      backgroundColor: context.background,
      body: Padding(
        padding: 16.px,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 24.h,
          children: [10.s, const CardPreview(), const _AddCardForm()],
        ),
      ).scrollable(),
    );
  }
}

class _AddCardForm extends StatefulWidget {
  const _AddCardForm();

  @override
  State<_AddCardForm> createState() => _AddCardFormState();
}

class _AddCardFormState extends State<_AddCardForm> {
  final _formKey = GlobalKey<FormState>();

  String name = '';
  String cardNumber = '';
  String expiryDate = '';
  String cvv = '';
  bool saveCard = true;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          CustomTextField(
            hint: 'Cardholder Name',
            // onChanged: (val) => setState(() => name = val),
            leading: const Icon(Icons.person_outline),
          ),
          16.s,
          CustomTextField(
            hint: 'Card Number',
            keyboardType: TextInputType.number,
            onChanged: (val) => setState(() => cardNumber = val),
            leading: const Icon(Icons.credit_card),
          ),
          16.s,
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  hint: 'MM/YY',
                  onChanged: (val) => setState(() => expiryDate = val),
                  keyboardType: TextInputType.datetime,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: CustomTextField(
                  hint: 'CVV',
                  onChanged: (val) => setState(() => cvv = val),
                  keyboardType: TextInputType.number,
                  obsecure: true,
                ),
              ),
            ],
          ),
          16.s,
          SwitchListTile(
            value: saveCard,
            title: Text('Save card for future use', style: context.bodyMedium),
            activeColor: context.primaryColor,
            onChanged: (val) => setState(() => saveCard = val),
          ),
          24.s,
          PrimaryButton(
            label: 'Add Card',
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                // Submit card details
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Card Added Successfully")),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class CardPreview extends StatelessWidget {
  const CardPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220.h,
      width: double.infinity,

      decoration: BoxDecoration(
        color: context.primaryColor,
        // borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: Svg(AssetSvgs.splashBGDark),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: context.shadow, blurRadius: 10)],
      ),
      padding: 20.px,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          12.s,

          /// Top Row: Card Brand Logo + Card Type Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(AssetImages.monalisa_app_001Card, height: 24.h),
              Image(image: Svg(AssetSvgs.cardType), height: 24.h),
            ],
          ),
          8.s,
          Image(image: Svg(AssetSvgs.flatChip), height: 36.h),
          const Spacer(),
          Text(
            '•••• •••• •••• 1234',
            style: context.titleLarge.copyWith(color: Colors.white),
          ),
          8.s,
          Text(
            'VALID THRU 12/25',
            style: context.bodySmall.copyWith(color: Colors.white70),
          ),
          12.s,
          Text(
            'John Doe',
            style: context.bodyMedium.copyWith(color: Colors.white),
          ),
          12.s,
        ],
      ),
    );
  }
}
