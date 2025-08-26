import 'package:flutter/material.dart';
import 'package:flutter_addons/flutter_addons.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:monalisa_app_001/src/components/appbar_builder.dart';

class FAQScreen extends StatelessWidget {
  static const String route = '/faq';

  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {
        'question': 'How do I add a new card?',
        'answer':
            'Go to the Cards section and tap the "+" button to add a new card securely.',
      },
      {
        'question': 'Is my wallet data secure?',
        'answer':
            'Yes. All your data is encrypted and stored securely with industry-standard practices.',
      },
      {
        'question': 'What if I forget my PIN?',
        'answer':
            'You can reset your PIN using your registered email or biometric verification.',
      },
      {
        'question': 'Can I link multiple bank accounts?',
        'answer':
            'Yes. Our app allows linking multiple bank accounts for better flexibility.',
      },
      {
        'question': 'How do I contact support?',
        'answer':
            'Go to Profile > Help & Support, or email us directly at support@walletapp.com.',
      },
    ];

    return Scaffold(
      appBar: buildNewAppBar(context, child: const CustomAppBar(title: 'FAQ')),
      body: ListView.separated(
        padding: 16.p,
        itemCount: faqs.length,
        separatorBuilder: (_, __) => 12.s,
        itemBuilder: (_, index) {
          final item = faqs[index];
          return _FaqTile(question: item['question']!, answer: item['answer']!);
        },
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final String question;
  final String answer;

  const _FaqTile({required this.question, required this.answer});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Material(
          color: context.cardBackground,
          elevation: 1,
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 12.h,
              ),
              title: Text(
                widget.question,
                style: context.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
              trailing: Icon(
                _expanded ? TablerIcons.chevron_up : TablerIcons.chevron_down,
                color: context.primaryColor,
                size: 20.sp,
              ),
              onExpansionChanged: (val) => setState(() => _expanded = val),
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    widget.answer,
                    style: context.bodyMedium.copyWith(
                      color: context.secondaryContent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
