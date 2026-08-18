import 'package:flutter/material.dart';

/// Coetus tasarım sistemi — renk, ölçü ve gölge token'ları.
/// Mockup'taki hex değerlerinin birebir karşılığı.
class CoetusColors {
  CoetusColors._();

  // Lacivert (birincil)
  static const navy = Color(0xFF1E3A63);
  static const navyInk = Color(0xFF152A4B);
  static const navyTint = Color(0xFFE7EBF2);

  // Sıcak vurgu
  static const coral = Color(0xFFE1703C);
  static const coralDeep = Color(0xFFC05A2A);
  static const coralSoft = Color(0x24E1703C); // rgba(225,112,60,.14)
  static const amber = Color(0xFFEFA53C);
  static const amberDeep = Color(0xFFA66B14);
  static const amberSoft = Color(0x2EEFA53C);

  // Nötr / zemin
  static const oat = Color(0xFFF5EFE4); // ekran zemini
  static const card = Color(0xFFFCFAF7); // kart zemini
  static const plateWarm = Color(0xFFF7E3C8); // görsel alanı
  static const plateWarmAlt = Color(0xFFFADFC8);

  // Metin
  static const ink = Color(0xFF1B2436);
  static const body = Color(0xFF3A4356);
  static const muted = Color(0xFF6E7482);
  static const hint = Color(0xFF8A8F9C);

  // Durum
  static const success = Color(0xFF3E8F6E);
  static const successDeep = Color(0xFF2F7357);
  static const successSoft = Color(0x263E8F6E);
  static const danger = Color(0xFFC9483A);

  static const border = Color(0x241E3A63); // rgba(30,58,99,.14)
  static const borderStrong = Color(0x401E3A63);
}

class CoetusRadius {
  CoetusRadius._();
  static const chip = 999.0;
  static const input = 14.0;
  static const card = 20.0;
  static const button = 18.0;
  static const sheet = 24.0;
}

class CoetusSpace {
  CoetusSpace._();
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 26.0;
  static const screenH = 20.0; // yatay ekran padding'i
}

class CoetusShadow {
  CoetusShadow._();

  /// Kartların yumuşak gölgesi — box-shadow: 0 2px 8px rgba(30,58,99,.07)
  static const card = <BoxShadow>[
    BoxShadow(color: Color(0x121E3A63), blurRadius: 8, offset: Offset(0, 2)),
  ];

  static const raised = <BoxShadow>[
    BoxShadow(color: Color(0x121E3A63), blurRadius: 10, offset: Offset(0, 2)),
  ];

  static const subtle = <BoxShadow>[
    BoxShadow(color: Color(0x0F1E3A63), blurRadius: 4, offset: Offset(0, 1)),
  ];
}
