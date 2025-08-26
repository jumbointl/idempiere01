import 'package:flutter/material.dart';

final List<CardModel> cardList = [
  CardModel(
    cardName: "Orkitt",
    expDate: "12/27",
    balance: 15230.75,
    bgColor: const Color(0xFF1F1F27), // Charcoal black with deep tone
  ),
  CardModel(
    cardName: "Swift",
    expDate: "08/26",
    balance: 8840.50,
    bgColor: const Color(0xFF2B0A0F), // Deep crimson for elite red card
  ),
  CardModel(
    cardName: "Verdant",
    expDate: "05/28",
    balance: 1200.00,
    bgColor: const Color(0xFF143D2A), // Dark forest green, calm + money tone
  ),
  CardModel(
    cardName: "Ambera",
    expDate: "03/25",
    balance: 703.45,
    bgColor: const Color(
      0xFF4B2E11,
    ), // Burnt amber, warm tone for bronze type card
  ),
  CardModel(
    cardName: "Viora",
    expDate: "07/29",
    balance: 22030.90,
    bgColor: const Color(0xFF3B1A5D), // Royal purple, prestige card
  ),
  CardModel(
    cardName: "Dusken",
    expDate: "11/26",
    balance: 330.00,
    bgColor: const Color(0xFF3A3A1C), // Dusky olive, toned-down utility card
  ),
  CardModel(
    cardName: "Cyanix",
    expDate: "06/30",
    balance: 6124.75,
    bgColor: const Color(0xFF0B3F46), // Teal cyan, sleek fintech vibe
  ),
  CardModel(
    cardName: "Velora",
    expDate: "01/27",
    balance: 480.80,
    bgColor: const Color(0xFF2C1B2E), // Plum violet, feminine + mysterious
  ),
  CardModel(
    cardName: "Tealos",
    expDate: "09/28",
    balance: 9890.00,
    bgColor: const Color(0xFF0E3A3A), // Deep jade teal
  ),
  CardModel(
    cardName: "Noctix",
    expDate: "02/31",
    balance: 400.00,
    bgColor: const Color(0xFF141432), // Midnight indigo, premium dark
  ),
];

class CardModel {
  final String cardName;
  final String expDate;
  final double balance;
  final Color bgColor;

  const CardModel({
    required this.cardName,
    required this.expDate,
    required this.balance,
    required this.bgColor,
  });
}
