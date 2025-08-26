import 'package:flutter_addons/flutter_addons.dart';
import 'route_export.dart';

class AppRouter {
  static const String initRoute = SplashPage.route;
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case initRoute:
        return PageAnimation.fadeTransition(const SplashPage());
      case IntroPage.route:
        return PageAnimation.slideFromLeftTransition(IntroPage());
      case LoginPage.route:
        return PageAnimation.slideFromRightTransition(const LoginPage());
      case SignupPage.route:
        return PageAnimation.slideFromRightTransition(const SignupPage());
      case HomePage.route:
        return PageAnimation.slideFromRightTransition(const HomePage());
      case TransferHistory.route:
        return PageAnimation.slideFromRightTransition(TransferHistory());
      case ContactPage.route:
        return PageAnimation.slideFromLeftTransition(ContactPage());
      case SelectAmount.route:
        return PageAnimation.slideFromBottomTransition(SelectAmount());
      case SelectCard.route:
        return PageAnimation.slideFromLeftTransition(SelectCard());
      case ReceivePage.route:
        return PageAnimation.slideFromLeftTransition(ReceivePage());
      case SaveTransactionHistory.route:
        return PageAnimation.slideFromBottomTransition(
          SaveTransactionHistory(),
        );
      case AddFingerprint.route:
        return PageAnimation.slideFromLeftTransition(AddFingerprint());
      case ChangePasswordScreen.route:
        return PageAnimation.fadeTransition(ChangePasswordScreen());
      case FAQScreen.route:
        return PageAnimation.slideFromLeftTransition(FAQScreen());
      case ForgotPasswordScreen.route:
        return PageAnimation.slideFromLeftTransition(ForgotPasswordScreen());
      case PhoneInputScreen.route:
        return PageAnimation.slideFromLeftTransition(PhoneInputScreen());
      case AddCardScreen.route:
        return PageAnimation.slideFromLeftTransition(AddCardScreen());
      case CreatePinScreen.route:
        return PageAnimation.slideFromRightTransition(CreatePinScreen());
      case OtpVerificationScreen.route:
        return PageAnimation.slideFromLeftTransition(OtpVerificationScreen());

      case AccountInfoScreen.route:
        return PageAnimation.slideFromRightTransition(AccountInfoScreen());
      case QrScannerScreen.route:
        return PageAnimation.slideFromBottomTransition(QrScannerScreen());
      case EditAccountScreen.route:
        return PageAnimation.slideFromLeftTransition(EditAccountScreen());
      case NotificationScreen.route:
        return PageAnimation.slideFromLeftTransition(NotificationScreen());
      case ReferralScreen.route:
        return PageAnimation.slideFromLeftTransition(ReferralScreen());
      default:
        return PageAnimation.fadeTransition(
          ErrorPage('Error 404\nRoute ${settings.name} Not found'),
        );
    }
  }
}
