import 'package:flutter/material.dart';
import 'package:flutter_addons/flutter_addons.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:monalisa_app_001/src/components/circle_button.dart';
import 'package:monalisa_app_001/src/components/app_search_bar.dart';
import 'package:monalisa_app_001/src/core/constants/app_constants.dart';
import 'package:monalisa_app_001/src/pages/select_amount/select_amount.dart';
import 'package:monalisa_app_001/src/widgets/global_layout.dart';

class ContactPage extends StatelessWidget {
  static const String route = '/add_people';

  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: GlobalPageLayout(
        headerPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
        header: DefaultLayoutHeader(title: 'Sent Money To'),
        footer: const PersonContent(),
        contentHeight: 0.82,
      ),
    );
  }
}

class DefaultLayoutHeader extends StatelessWidget {
  final String title;
  const DefaultLayoutHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleIconButton(
          icon: TablerIcons.arrow_back,
          iconColor: context.primaryColor,
          onPressed: () => context.pop(),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: context.titleSmall.copyWith(
            color: context.titleInverse,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class PersonContent extends StatelessWidget {
  const PersonContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: context.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 12.h),

          /// Search
          AppSearchBar(
            svgIconPath: 'assets/icons/search.svg',
            onChanged: (value) => print('Searching: $value'),
          ),

          kMargin.s,

          /// Main scrollable content
          Expanded(child: _buildScrollable(context)),
        ],
      ),
    );
  }

  Widget _buildScrollable(BuildContext context) {
    final fakeUser = generateDummyPersons(10);
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Recents Title
          Text(
            'Recents',
            style: context.bodyLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          kMargin.s,

          /// Recent avatars row
          SizedBox(
            height: 100.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 8,
              separatorBuilder: (_, __) => SizedBox(width: 20.w),
              itemBuilder: (_, i) {
                return Column(
                  children: [
                    CircleAvatar(
                      radius: 30.r,
                      backgroundImage: NetworkImage(
                        'https://randomuser.me/api/portraits/men/$i.jpg',
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      fakeUser[i].name,
                      style: context.bodySmall.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                );
              },
            ),
          ),

          kMargin.s,

          /// Contacts Title
          Text(
            'Contacts',
            style: context.bodyLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          kMargin.s,

          /// Add new contact tile
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: context.primaryColor.withValues(alpha: 0.1),
              radius: 28.r,
              child: Icon(Icons.add, color: context.primaryColor, size: 28.sp),
            ),
            title: Text('Add new contact'),
            subtitle: Text(
              'Contact details or info',
              style: context.bodySmall.copyWith(
                color: context.secondaryContent,
              ),
            ),
            onTap: () {},
          ),

          /// Contact list
          Column(
            children: List.generate(
              10,
              (index) => Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 28.r,
                    backgroundImage: NetworkImage(
                      'https://randomuser.me/api/portraits/women/$index.jpg',
                    ),
                  ),
                  title: Text(
                    fakeUser[index].name,
                    style: context.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    fakeUser[index].email,
                    style: context.bodySmall.copyWith(
                      color: context.secondaryContent,
                    ),
                  ),
                  onTap: () {
                    Future.microtask(() {
                      if (context.mounted) {
                        context.pushName(SelectAmount.route);
                      }
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
