import 'package:flutter_addons/flutter_addons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:monalisa_app_001/src/core/resource/app_resources.dart';
import 'package:monalisa_app_001/src/components/circle_button.dart';
import 'package:monalisa_app_001/src/core/routes/route_export.dart';
import 'package:monalisa_app_001/src/providers/providers.dart';
import 'package:monalisa_app_001/src/widgets/global_layout.dart';
import 'package:monalisa_app_001/src/widgets/section_title.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlobalPageLayout(
        contentHeight: .65,
        header: ProfileHeader(),
        footer: ProfileContent(),
      ),
    );
  }
}

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: 50.mt,
      child: Column(
        children: [
          AvatarCircle(
            image: AssetImage(AssetImages.person1),
            radius: 96,
            size: Size(96, 96),
            borderColor: context.titleInverse,
            onTap: () {
              context.pushName(EditAccountScreen.route);
            },
            badgeAlignment: Alignment.bottomRight,
            badgeOffset: const Offset(-3, -3),
            showBadge: true,
            customBadge: CircleIconButton(
              icon: TablerIcons.edit,
              size: 24,
              iconSize: 16,
            ),
          ),
          14.s,
          Text(
            'Marufa Akter',
            style: context.titleMedium.k(context.titleInverse),
          ),
          2.s,
          Text(
            'mailtomarufa@gmail.com',
            style: context.bodyMedium.k(context.titleInverse).bold,
          ),
        ],
      ),
    );
  }
}

class ProfileContent extends StatelessWidget {
  const ProfileContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: 16.p,
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          20.s,
          const SectionTitle(title: 'General'),
          SettingsTile(
            leading: TablerIcons.user_check,
            title: 'Account Info',
            onTap: () => context.pushName(AccountInfoScreen.route),
          ),
          SettingsTile(
            leading: TablerIcons.lock,
            title: 'Change Password',
            onTap: () => const ChangePasswordScreen().launch(context),
          ),

          SettingsTile(
            leading: TablerIcons.bell,
            title: 'Notification Settings',
            onTap: () => NotificationScreen().launch(context),
          ),

          Consumer(
            builder: (_, WidgetRef ref, __) {
              final themeManager = ref.watch(themeProvider);
              final isDarkMode = themeManager.themeMode == ThemeMode.dark;

              return SettingsTile(
                leading: TablerIcons.moon,
                title: 'Enable Dark Mode',
                trailing: Switch(
                  value: isDarkMode,
                  onChanged: (value) =>
                      ref.read(themeProvider.notifier).toggleTheme(),
                  activeColor: context.primaryColor,
                ),
              );
            },
          ),

          SettingsTile(
            leading: TablerIcons.language,
            title: 'Language',
            onTap: () {
              // TODO: Implement language settings
            },
          ),

          24.s,
          const SectionTitle(title: 'Wallet Settings'),

          SettingsTile(
            leading: TablerIcons.currency_dollar,
            title: 'Currency Preferences',
            onTap: () {
              // TODO: Currency preferences
            },
          ),

          SettingsTile(
            leading: TablerIcons.database_import,
            title: 'Backup & Restore Wallet',
            onTap: () {
              // TODO: Backup action
            },
          ),

          SettingsTile(
            leading: TablerIcons.arrows_left_right,
            title: 'Transaction Limits',
            onTap: () {
              // TODO: Transaction limits
            },
          ),

          SettingsTile(
            leading: TablerIcons.fingerprint,
            title: 'Biometric Authentication',
            trailing: Switch(
              value: true, // TODO: bind to actual state
              onChanged: (value) {
                // TODO: toggle biometric
              },
              activeColor: context.primaryColor,
            ),
            onTap: () => context.pushName(AddFingerprint.route),
          ),

          24.s,
          const SectionTitle(title: 'Support'),

          SettingsTile(
            leading: TablerIcons.user_plus,
            title: 'Refer to Friends',
            onTap: () {
              // TODO: Refer to friends
              context.pushName(ReferralScreen.route);
            },
          ),

          SettingsTile(
            leading: TablerIcons.user_circle,
            title: 'Contact List',
            onTap: () {
              // TODO: Open contact list
              context.pushName(ContactPage.route);
            },
          ),

          SettingsTile(
            leading: TablerIcons.help_circle,
            title: 'FAQ',
            onTap: () {
              // TODO: Open FAQ
              context.pushName(FAQScreen.route);
            },
          ),

          24.s,
          const SectionTitle(title: 'Account'),

          SettingsTile(
            leading: TablerIcons.logout,
            title: 'Logout',
            onTap: () => context.pushName(LoginPage.route),
          ),
        ],
      ),
    ).scrollable();
  }
}

/// Reusable settings tile widget
class SettingsTile extends StatelessWidget {
  final IconData leading;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SettingsTile({
    super.key,
    required this.leading,
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabledColor = Theme.of(context).disabledColor;

    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          minLeadingWidth: 0,
          leading: Icon(leading, color: Theme.of(context).primaryColor),
          title: Text(title),
          trailing:
              trailing ??
              Icon(Icons.arrow_forward_ios, size: 16, color: disabledColor),
          onTap: onTap,
        ),
        Divider(color: Theme.of(context).dividerColor),
      ],
    );
  }
}

/// Section title for grouping settings
