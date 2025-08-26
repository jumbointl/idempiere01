import 'package:flutter_addons/flutter_addons.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:monalisa_app_001/src/core/routes/route_export.dart';

Future<void> showSentMoneySuccessDialog(BuildContext context) async {
  return showDialog(
    context: context,
    barrierDismissible: true,
    useRootNavigator: false,
    builder: (BuildContext context) {
      return Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Custom shaped dialog with curved top
            Container(
              margin: const EdgeInsets.only(top: 50),
              child: ClipPath(
                clipper: TopNotchClipper(),
                child: Container(
                  padding: const EdgeInsets.only(
                    top: 70,
                    bottom: 32,
                    left: 24,
                    right: 24,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: context.background,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 15,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Transaction Successful',
                        style: context.titleSmall.k(context.titleColor),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'You’ve successfully transferred money',
                        style: context.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: context.cardBackground,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Text(
                              120.toDollar(),
                              style: context.displayMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Sent Successfully',
                              style: context.bodyMedium.copyWith(
                                color: context.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),
                      _infoTile(
                        context,
                        'From',
                        'Credit Card',
                        'Anika Bergson',
                        'VISA *9067',
                      ),
                      Divider(),
                      _infoTile(
                        context,
                        'To',
                        'Bank Account',
                        'Emery Dokidis',
                        'AC **2103',
                      ),
                      Divider(),
                      _infoTile(context, 'Date', '', '30 Mar 2022', '09:20 AM'),
                      SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // TODO: save receipt
                                context.pushName(SaveTransactionHistory.route);
                              },
                              icon: Icon(
                                TablerIcons.receipt_dollar,
                                color: context.primaryColor,
                                size: 20,
                              ),
                              label: Text(
                                'Receipt',
                                style: context.bodySmall.k(
                                  context.primaryColor,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: context.primaryColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              top: 0,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: context.primaryColor,
                child: Icon(
                  TablerIcons.check,
                  size: 50,
                  color: context.titleInverse,
                ),
              ),
            ),
          ],
        ),
      );
    },
  ).then((x) {
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        HomePage.route,
        (route) => false, 
      );
    }
  });
}



class TopNotchClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const double notchWidth = 100;
    const double notchHeight = 40;

    final double notchRadius = notchWidth / 2;
    final double centerX = size.width / 2;

    final double startNotchX = centerX - notchRadius;
    final double endNotchX = centerX + notchRadius;

    final Path path = Path();

    // Start from top-left
    path.moveTo(0, 0);

    // Line to start of notch
    path.lineTo(startNotchX, 0);

    // Downward curve (concave)
    path.quadraticBezierTo(
      centerX,
      notchHeight, // control point
      endNotchX,
      0, // end of notch
    );

    // Continue to right edge
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

Widget _infoTile(
  BuildContext context,
  String title,
  String subtitle,
  String trailingTitle,
  String trailingSub,
) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.bodySmall),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: context.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
        SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              trailingTitle,
              style: context.bodyMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(trailingSub, style: context.bodySmall),
          ],
        ),
      ],
    ),
  );
}
