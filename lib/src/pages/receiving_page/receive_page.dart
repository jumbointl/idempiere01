import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_addons/flutter_addons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/src/core/resource/app_resources.dart';
import 'package:monalisa_app_001/src/components/appbar_builder.dart';
import 'package:monalisa_app_001/src/components/primary_button.dart';

class ReceivePage extends ConsumerWidget {
  static const String route = '/receive';
  const ReceivePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.background,
      appBar: buildNewAppBar(context, child: CustomAppBar(title: '')),
      body: Padding(
        padding: 16.px,
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  20.s,
                  _buildHeader(context),
                  20.s,
                  Expanded(child: _buildBody(context)),
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('Receive Money', style: context.titleMedium),
        5.s,
        Text(
          'Share your QR or account to receive money.',
          style: context.titleSmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    const qrAssetPath = AssetImages.sampleQr;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Container(
          height: 220,
          width: 220,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.outline),
            boxShadow: [
              BoxShadow(
                color: context.outline,
                offset: Offset(-1, 5),
                blurRadius: 10,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(qrAssetPath, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 20),
        Text('Account Number', style: context.labelLarge),
        8.s,
        SelectableText(
          '1234 5678 9012 3456',
          style: context.titleMedium.copyWith(letterSpacing: 1.5),
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          label: 'Copy Account Number',
          dataIcon: Icons.copy_outlined,
          onPressed: () {
            Clipboard.setData(const ClipboardData(text: '1234567890123456'));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Account number copied!')),
            );
          },
        ),
      ],
    );
  }
}
