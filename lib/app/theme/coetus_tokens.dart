import 'package:flutter/material.dart';

/// Shared palette used by every Coetus screen.
class CoetusPalette {
  CoetusPalette._();

  static const lavender = Color(0xFFBB97F5);
  static const purple = Color(0xFF492080);
  static const purpleInk = Color(0xFF291044);
  // Compatibility alias; all accents stay inside the brand palette.
  static const blue = purple;
  static const lime = Color(0xFFDEFF8A);
  static const pink = Color(0xFFFF547B);
  static const red = Color(0xFFFF547B);
  static const redSoft = Color(0xFFFFE3EB);
  static const onRed = Color(0xFF291044);
  static const cream = Color(0xFFF8F4FF);
  static const softLavender = Color(0xFFEBDFFF);
}

/// Legacy names remain aliases so existing screens share the refreshed theme.
class CoetusColors {
  CoetusColors._();

  static const navy = CoetusPalette.purple;
  static const navyInk = CoetusPalette.purpleInk;
  static const navyTint = CoetusPalette.softLavender;
  static const coral = CoetusPalette.red;
  static const coralDeep = CoetusPalette.purple;
  static const coralSoft = Color(0x24FF547B);
  static const amber = CoetusPalette.lime;
  static const amberDeep = CoetusPalette.purple;
  static const amberSoft = Color(0x80DEFF8A);
  static const oat = CoetusPalette.lavender;
  static const card = CoetusPalette.cream;
  static const plateWarm = CoetusPalette.lime;
  static const plateWarmAlt = CoetusPalette.softLavender;
  static const ink = CoetusPalette.purpleInk;
  static const body = Color(0xFF49315E);
  static const muted = Color(0xFF4D3265);
  static const hint = Color(0xFF56366D);
  static const success = Color(0xFF397044);
  static const successDeep = Color(0xFF285A32);
  static const successSoft = Color(0xFFE3F4CF);
  static const danger = Color(0xFFB1254C);
  static const border = Color(0x24492080);
  static const borderStrong = Color(0x40492080);
}

class CoetusRadius {
  CoetusRadius._();
  static const chip = 999.0;
  static const input = 20.0;
  static const card = 28.0;
  static const button = 999.0;
  static const sheet = 32.0;
}

class CoetusSpace {
  CoetusSpace._();
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 26.0;
  static const screenH = 20.0;
}

class CoetusShadow {
  CoetusShadow._();
  static const card = <BoxShadow>[
    BoxShadow(color: Color(0x12492080), blurRadius: 12, offset: Offset(0, 3)),
  ];
  static const raised = <BoxShadow>[
    BoxShadow(color: Color(0x20492080), blurRadius: 18, offset: Offset(0, 6)),
  ];
  static const subtle = <BoxShadow>[
    BoxShadow(color: Color(0x0F492080), blurRadius: 6, offset: Offset(0, 2)),
  ];
}
