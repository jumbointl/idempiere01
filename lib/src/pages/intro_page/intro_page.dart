import 'package:flutter_addons/flutter_addons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/src/components/primary_button.dart';
import 'package:monalisa_app_001/src/core/routes/route_export.dart';
import 'package:monalisa_app_001/src/data/samples/intro_data.dart';
import 'package:monalisa_app_001/src/pages/intro_page/intro_provider.dart';

class IntroPage extends ConsumerWidget {
  static const String route = '/intro';

  const IntroPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(introProvider);

    return Scaffold(
      appBar: buildNewAppBar(
        context,
        child: Align(
          alignment: Alignment.centerRight,
          child: _buildTopButton(context, viewModel),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 24.h),
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: viewModel.pageController,
                onPageChanged: viewModel.setPage,
                itemCount: IntroViewModel.introLength,
                itemBuilder: (context, index) {
                  final item = introItems[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!context.isLandscape)
                        Center(
                          child: Image.asset(item.imagePath, height: 250.h),
                        ),
                      if (!context.isLandscape) 20.s,
                      _buildPageIndicator(context, viewModel),
                      33.s,
                      Text(
                        item.title,
                        style: context.labelMedium.copyWith(
                          color: context.secondaryContent,
                        ),
                      ),
                      10.s,
                      Text(
                        item.description,
                        style: context.displayMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.2.h,
                          letterSpacing: 1.2.w,
                        ),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  );
                },
              ),
            ),
            44.s,
            _buildBottomButtons(context, viewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildTopButton(BuildContext context, IntroViewModel viewModel) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28.w),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
            side: BorderSide(color: context.outline),
          ),
          backgroundColor: context.secondaryButton,
          elevation: 0,
        ),
        onPressed: () async {
          if (!viewModel.isLastPage) {
            viewModel.pageController.nextPage(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          } else {
            await viewModel.completeIntro();
            context.pushName(LoginPage.route);
          }
        },
        child: Text(
          viewModel.isLastPage ? "Get Started" : "Skip",
          style: context.labelMedium.copyWith(
            fontSize: 14.sp,
            color: context.titleColor,
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator(BuildContext context, IntroViewModel viewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(IntroViewModel.introLength, (index) {
        final isActive = viewModel.currentPage == index;
        return AnimatedContainer(
          duration: Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 5),
          width: isActive ? 36 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? context.primaryColor : context.surfaceContent,
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }),
    );
  }

  Widget _buildBottomButtons(BuildContext context, IntroViewModel viewModel) {
    return Column(
      children: [
        PrimaryButton(
          label: 'Login',
          onPressed: () async {
            await viewModel.completeIntro();
            context.pushName(LoginPage.route);
          },
        ),
        20.s,
        PrimaryButton(
          label: 'Create an account',
          color: context.secondaryButton,
          textColor: context.bodyTextColor,
          borderColor: context.outline,
          onPressed: () async {
            await viewModel.completeIntro();
            context.pushName(SignupPage.route);
          },
        ),
      ],
    );
  }
}
