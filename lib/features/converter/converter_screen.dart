import 'package:flutter/material.dart';

import 'package:divefriend/app_services.dart';
import 'package:divefriend/features/converter/currency_converter_card.dart';
import 'package:divefriend/features/converter/time_converter_card.dart';

/// Layar Konversi: kalkulator mata uang (kurs dari Frankfurter) dan konverter waktu.
class ConverterScreen extends StatelessWidget {
  const ConverterScreen({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Konversi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CurrencyConverterCard(rates: services.rates),
          const TimeConverterCard(),
        ],
      ),
    );
  }
}
