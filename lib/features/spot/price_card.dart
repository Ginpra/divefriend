import 'package:flutter/material.dart';

import 'package:divefriend/core/currencies.dart';
import 'package:divefriend/core/formatters.dart';
import 'package:divefriend/core/widgets/inline_notice.dart';
import 'package:divefriend/core/widgets/section_card.dart';
import 'package:divefriend/data/models/exchange_rates.dart';
import 'package:divefriend/data/models/spot.dart';
import 'package:divefriend/services/api_failure.dart';
import 'package:divefriend/services/exchange_rate_service.dart';

/// Harga paket simulasi dalam empat mata uang. Harga Rupiah selalu tampil karena datang dari
/// data spot. Tiga mata uang lain butuh kurs dari internet, kalau gagal tampil pesan dan
/// tombol coba lagi, sedangkan harga Rupiah tetap terlihat.
class PriceCard extends StatefulWidget {
  const PriceCard({super.key, required this.spot, required this.rates});

  final Spot spot;
  final ExchangeRateService rates;

  @override
  State<PriceCard> createState() => _PriceCardState();
}

class _PriceCardState extends State<PriceCard> {
  late Future<ExchangeRates> _ratesFuture;

  @override
  void initState() {
    super.initState();
    _ratesFuture = widget.rates.fetchLatest();
  }

  void _retry() {
    setState(() {
      _ratesFuture = widget.rates.fetchLatest(forceRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final priceIdr = widget.spot.priceEstimateIdr;
    return SectionCard(
      icon: Icons.sell_outlined,
      title: 'Paket selam',
      badge: 'Harga simulasi',
      // FutureBuilder selalu dipasang (walau harga kosong) supaya error kurs ikut tertangani.
      child: FutureBuilder<ExchangeRates>(
        future: _ratesFuture,
        builder: (context, snapshot) {
          if (priceIdr == null) {
            return const Text('Harga simulasi belum ditetapkan untuk spot ini.');
          }
          return _buildPrices(priceIdr, snapshot);
        },
      ),
    );
  }

  Widget _buildPrices(int priceIdr, AsyncSnapshot<ExchangeRates> snapshot) {
    final rates = snapshot.data;
    final error = snapshot.error;
    final waiting = snapshot.connectionState == ConnectionState.waiting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final code in priceCurrencyCodes)
          _PriceRow(
            currency: currencyByCode(code),
            valueText: _valueText(code, priceIdr, rates, waiting),
          ),
        const SizedBox(height: 8),
        if (error != null)
          InlineNotice(
            icon: Icons.cloud_off,
            message: failureText(error, 'kurs'),
            onRetry: _retry,
          ),
        const Text(
          'Harga paket simulasi per orang untuk satu hari selam dengan dua kali penyelaman. '
          'Angkanya ditetapkan tim untuk keperluan tugas, bukan tarif operator selam mana pun.',
          textAlign: TextAlign.justify,
          style: TextStyle(fontSize: 12, height: 1.35),
        ),
        if (rates != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Kurs acuan Frankfurter (data Bank Sentral Eropa), tanggal ${rates.date}.',
              style: const TextStyle(fontSize: 11),
            ),
          ),
      ],
    );
  }

  String _valueText(String code, int priceIdr, ExchangeRates? rates, bool waiting) {
    final currency = currencyByCode(code);
    if (code == 'IDR') return formatMoney(priceIdr.toDouble(), currency);
    if (waiting) return 'memuat';
    final converted = rates?.convert(priceIdr.toDouble(), 'IDR', code);
    return converted == null ? 'tidak tersedia' : formatMoney(converted, currency);
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.currency, required this.valueText});

  final Currency currency;
  final String valueText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(currency.name)),
          Text(
            valueText,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
