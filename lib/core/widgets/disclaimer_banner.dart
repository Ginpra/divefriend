import 'package:flutter/material.dart';

import 'package:divefriend/core/app_theme.dart';

/// Catatan wajib sesuai brief: informasi umum, bukan pengganti instruktur bersertifikat.
/// Dibuat ringkas satu baris tanpa kotak supaya tampilan tetap bersih, tapi tetap terbaca.
class DisclaimerBanner extends StatelessWidget {
  const DisclaimerBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.xs),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 14, color: AppColors.textMuted),
          SizedBox(width: AppSpace.xs),
          Expanded(
            child: Text(
              'Informasi umum, bukan pengganti instruktur selam bersertifikat.',
              style: TextStyle(fontSize: 11, height: 1.4, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
