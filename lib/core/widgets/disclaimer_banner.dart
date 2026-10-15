import 'package:flutter/material.dart';

/// Banner wajib sesuai brief: informasi umum, bukan pengganti instruktur bersertifikat.
class DisclaimerBanner extends StatelessWidget {
  const DisclaimerBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFF3E0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: Color(0xFF5D3A00)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Informasi umum, bukan pengganti instruktur selam bersertifikat.',
              style: TextStyle(fontSize: 12, color: Color(0xFF5D3A00)),
            ),
          ),
        ],
      ),
    );
  }
}
