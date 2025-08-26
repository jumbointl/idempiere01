import 'package:flutter_addons/flutter_addons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:monalisa_app_001/src/core/resource/app_resources.dart';
import 'package:monalisa_app_001/src/core/routes/route_export.dart';
import 'package:monalisa_app_001/src/pages/intro_page/intro_provider.dart';

class SplashPage extends StatefulWidget {
  static const String route = '/splash';
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    TextTheme t = Theme.of(context).textTheme;
    return Scaffold(
      body: Stack(
        alignment: AlignmentDirectional.center,
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
              color: context.primaryColor,
              image: DecorationImage(
                image: Svg(AssetSvgs.splashBGDark),
                fit: BoxFit.cover,
              ),
            ),
          ),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 10.h,
            children: [
              Image(
                width: 161.w,
                height: 164.h,
                image: Svg(AssetSvgs.splashLogoLight),
              ),
              Text(
                'monalisa_app_001',
                style: t.displayLarge!.copyWith(color: Colors.white),
              ),
              10.s,
              Consumer(
                builder: (context, ref, _) {
                  final viewModel = ref.read(introProvider);
                  return FutureBuilder<bool>(
                    future: viewModel.isIntroAlreadySeen(),
                    builder: (context, snapshot) {
                      return MiniProgressBar(
                        duration: 5.seconds,
                        color: Kolors.indigo300,
                        background: context.titleColor,
                        onComplete: () {
                          if (!context.mounted) return;
                          final hasSeenIntro = snapshot.data ?? false;
                          Future.microtask(() {
                            if (!context.mounted) return;
                            final targetRoute = hasSeenIntro
                                ? LoginPage.route
                                : IntroPage.route;
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              targetRoute,
                              (route) => false,
                            );
                          });
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
