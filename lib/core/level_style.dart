import 'package:flutter/material.dart';

import 'package:divefriend/data/models/spot.dart';

/// Warna lencana level. Sengaja ada di lapisan tampilan (bukan di model data)
/// supaya model tetap murni Dart. Palet dibuat netral: tidak ada kesan "aman/tidak aman".
extension SpotLevelStyle on SpotLevel {
  Color get color {
    switch (this) {
      case SpotLevel.pemula:
        return const Color(0xFF0E7C86);
      case SpotLevel.menengah:
        return const Color(0xFF2A5CAA);
      case SpotLevel.lanjutan:
        return const Color(0xFF5B3A9E);
    }
  }
}
