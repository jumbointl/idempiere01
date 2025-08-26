import 'dart:async';

import 'package:flutter_addons/flutter_addons.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:monalisa_app_001/src/components/circle_button.dart';
import 'package:monalisa_app_001/src/core/resource/app_resources.dart';
import 'package:monalisa_app_001/src/core/routes/route_export.dart';
import 'package:monalisa_app_001/src/pages/profile_page/profile_view.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          AvatarCircle(
            image: AssetImage(AssetImages.person1),
            radius: 24,
            size: const Size(48, 48),
            borderColor: Kolors.slate900,
            onTap: () => ProfileView().launch(context),
            badgeAlignment: Alignment.bottomRight,
            badgeOffset: const Offset(3, -3),
            showBadge: true,
          ),
          SizedBox(width: 12.w),
          Expanded(child: AnimatedGreeting()),
          // Expanded(
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: [
          //       Text('Welcome back,', style: context.bodySmall),
          //       SizedBox(height: 2.h),
          //       Text(
          //         'Marufa Akter',
          //         style: context.bodyMedium.bold
          //       ),
          //     ],
          //   ),
          // ),
          CircleIconButton(
            icon: TablerIcons.bell,
            size: 48,
            onPressed: () => NotificationScreen().launch(context),
            backgroundColor: context.primaryColor.withValues(alpha: 0.1),
            iconColor: context.primaryColor,
          ),
        ],
      ),
    );
  }
}

class AnimatedGreeting extends StatefulWidget {
  const AnimatedGreeting({super.key});

  @override
  State<AnimatedGreeting> createState() => _AnimatedGreetingState();
}

class _AnimatedGreetingState extends State<AnimatedGreeting>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  Timer? _revertTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  void _showBalanceTemporarily() {
    _revertTimer?.cancel();

    _controller.forward();

    _revertTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _revertTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showBalanceTemporarily,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          const _InfoCard(
            key: ValueKey('greeting'),
            title: 'Welcome back,',
            subtitle: 'Marufa Akter',
          ),
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                color: context.background,
                child: const _InfoCard(
                  key: ValueKey('balance'),
                  title: 'Balance:',
                  subtitle: '\$5,678',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _InfoCard({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      width: 150.w,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          2.s,
          Text(title, style: context.bodySmall),
          2.s,
          Text(subtitle, style: context.bodyMedium.bold),
        ],
      ),
    );
  }
}
