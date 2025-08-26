import 'package:flutter/material.dart';
import 'package:flutter_addons/flutter_addons.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:monalisa_app_001/src/components/appbar_builder.dart';
import 'package:monalisa_app_001/src/pages/edit_account/edit_account_details.dart';

class AccountInfoScreen extends StatelessWidget {
  static const String route = '/account-info';

  const AccountInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final accountInfo = {
      'Account Holder': 'John Doe',
      'Account Number': '1234 5678 9012',
      'Bank Name': 'State Bank of India',
      'IFSC Code': 'SBIN0001234',
      'SWIFT Code': 'SBININBBXXX',
    };

    return Scaffold(
      appBar: buildNewAppBar(
        context,
        child: CustomAppBar(
          title: 'Account Info',
          actions: [
            IconButton(
              icon: const Icon(TablerIcons.user_edit),
              onPressed: () {
                context.pushName(EditAccountScreen.route);
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: 16.p,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...accountInfo.entries.map(
              (entry) => _InfoTile(
                label: entry.key,
                value: entry.value,
                icon: _getIcon(entry.key),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String label) {
    switch (label) {
      case 'Account Holder':
        return TablerIcons.user;
      case 'Account Number':
        return TablerIcons.hash;
      case 'Bank Name':
        return TablerIcons.building_bank;
      case 'IFSC Code':
        return TablerIcons.barcode;
      case 'SWIFT Code':
        return TablerIcons.code;
      default:
        return TablerIcons.info_circle;
    }
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.outline),
        //boxShadow: kElevationToShadow[1],
      ),
      child: Row(
        children: [
          Icon(icon, color: context.primaryColor, size: 20),
          12.s,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.labelMedium.copyWith(color: Colors.grey[600]),
                ),
                4.s,
                Text(
                  value,
                  style: context.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
