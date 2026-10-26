import 'package:flutter/material.dart';

import 'package:divefriend/core/app_theme.dart';
import 'package:divefriend/core/currencies.dart';
import 'package:divefriend/core/formatters.dart';
import 'package:divefriend/core/widgets/inline_notice.dart';
import 'package:divefriend/core/widgets/section_card.dart';
import 'package:divefriend/data/models/exchange_rates.dart';
import 'package:divefriend/services/api_failure.dart';
import 'package:divefriend/services/exchange_rate_service.dart';

/// Kalkulator mata uang: jumlah, mata uang asal, mata uang tujuan. Hasil dihitung
/// ulang setiap kali pengguna mengetik atau memilih. Kurs diambil sekali saat layar
/// dibuka (hasilnya dipakai bersama layar lain lewat ExchangeRateService).
class CurrencyConverterCard extends StatefulWidget {
  const CurrencyConverterCard({super.key, required this.rates});

  final ExchangeRateService rates;

  @override
  State<CurrencyConverterCard> createState() => _CurrencyConverterCardState();
}

class _CurrencyConverterCardState extends State<CurrencyConverterCard> {
  final _amountController = TextEditingController(text: '100');
  late Future<ExchangeRates> _ratesFuture;
  String _from = 'USD';
  String _to = 'IDR';

  @override
  void initState() {
    super.initState();
    _ratesFuture = widget.rates.fetchLatest();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _retry() {
    setState(() {
      _ratesFuture = widget.rates.fetchLatest(forceRefresh: true);
    });
  }

  void _selectFrom(String code) {
    setState(() {
      _from = code;
    });
  }

  void _selectTo(String code) {
    setState(() {
      _to = code;
    });
  }

  /// Menukar mata uang asal dan tujuan.
  void _swap() {
    setState(() {
      final previousFrom = _from;
      _from = _to;
      _to = previousFrom;
    });
  }

  /// Menerima koma atau titik sebagai pemisah desimal. Null kalau bukan angka.
  double? get _amount {
    return double.tryParse(_amountController.text.trim().replaceAll(',', '.'));
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      icon: Icons.currency_exchange,
      title: 'Kalkulator mata uang',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) {
              setState(() {});
            },
            decoration: const InputDecoration(
              labelText: 'Jumlah',
              helperText: 'Tulis angka saja, tanpa titik pemisah ribuan',
            ),
          ),
          const SizedBox(height: 12),
          const Text('Dari', style: TextStyle(fontWeight: FontWeight.w600)),
          _CurrencyChips(selected: _from, onSelected: _selectFrom),
          Align(
            child: IconButton(
              key: const Key('swap_currency'),
              tooltip: 'Tukar mata uang',
              onPressed: _swap,
              icon: const Icon(Icons.swap_vert_rounded, color: AppColors.tealDeep),
            ),
          ),
          const Text('Ke', style: TextStyle(fontWeight: FontWeight.w600)),
          _CurrencyChips(selected: _to, onSelected: _selectTo),
          const Divider(height: 28),
          FutureBuilder<ExchangeRates>(
            future: _ratesFuture,
            builder: _buildResult,
          ),
        ],
      ),
    );
  }

  Widget _buildResult(BuildContext context, AsyncSnapshot<ExchangeRates> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    final error = snapshot.error;
    if (error != null) {
      return InlineNotice(
        icon: Icons.cloud_off,
        message: failureText(error, 'kurs'),
        onRetry: _retry,
      );
    }
    final rates = snapshot.data;
    final amount = _amount;
    if (rates == null) {
      return const InlineNotice(icon: Icons.info_outline, message: 'Kurs belum tersedia.');
    }
    if (amount == null) {
      return const InlineNotice(
        icon: Icons.edit_outlined,
        message: 'Masukkan jumlah berupa angka untuk melihat hasilnya.',
      );
    }
    final converted = rates.convert(amount, _from, _to);
    if (converted == null) {
      return const InlineNotice(
        icon: Icons.info_outline,
        message: 'Kurs untuk pasangan mata uang ini tidak tersedia.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpace.lg),
          decoration: BoxDecoration(
            gradient: AppGradients.deepSea,
            borderRadius: BorderRadius.circular(AppRadius.field + 4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatMoney(amount, currencyByCode(_from)),
                style: const TextStyle(fontSize: 14, color: AppColors.mintSoft),
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                '= ${formatMoney(converted, currencyByCode(_to))}',
                key: const Key('currency_result'),
                style: const TextStyle(fontFamily: AppFonts.heading, fontSize: 28, color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        Text(
          'Kurs acuan Frankfurter (data Bank Sentral Eropa), tanggal ${rates.date}. '
          'Kurs diperbarui setiap hari kerja, jadi bisa berbeda dengan kurs di tempat penukaran.',
          textAlign: TextAlign.justify,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _CurrencyChips extends StatelessWidget {
  const _CurrencyChips({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        for (final currency in supportedCurrencies)
          ChoiceChip(
            label: Text(currency.code),
            selected: selected == currency.code,
            onSelected: (_) => onSelected(currency.code),
          ),
      ],
    );
  }
}
