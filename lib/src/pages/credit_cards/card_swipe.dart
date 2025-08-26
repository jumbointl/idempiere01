import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_addons/flutter_addons.dart';
import 'package:monalisa_app_001/src/data/samples/card_data.dart';
import 'package:monalisa_app_001/src/pages/credit_cards/virtual_card.dart';

class CardSwipe extends StatelessWidget {
  const CardSwipe({super.key});

  @override
  Widget build(BuildContext context) {
    return Swiper(
      itemBuilder: (BuildContext context, int index) {
        final card = cardList[index];
        return VirtualCard(
          name: card.cardName,
          bgColor: card.bgColor,
          amount: card.balance,
          expiry: card.expDate,
        ).onTap(() {
          debug(card.cardName);
        });
      },
      itemCount: cardList.length,
      autoplay: false,
      itemWidth: context.getWidth,
      itemHeight: 220.h,
      layout: SwiperLayout.STACK,
    );
  }
}
