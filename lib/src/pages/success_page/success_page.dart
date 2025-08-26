import 'package:flutter_addons/flutter_addons.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:monalisa_app_001/src/core/resource/app_resources.dart';
import 'package:monalisa_app_001/src/components/appbar_builder.dart';
import 'package:monalisa_app_001/src/core/routes/route_export.dart';

class SuccessPage extends StatelessWidget {
  const SuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildNewAppBar(
        context,
        child: CustomAppBar(onBackPressed: () => HomePage().launch(context)),
      ),
      // ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image(image: Svg(AssetSvgs.success), height: 194.h, width: 227.w),
            53.s,
            Text(
              'Congrats!',
              style: context.titleMedium,
              textAlign: TextAlign.center,
            ),
            5.s,
            Text(
              'Your Account is\nsuccesfully created',
              style: context.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
