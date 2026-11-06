/// Colori e temi Material You (spec-viste-app §6).
library;

import 'package:flutter/material.dart';

import '../data/settings.dart';

class SeedPreset {
  const SeedPreset(this.id, this.color);

  /// Chiave per la traduzione del nome.
  final String id;
  final Color color;
}

/// Seed predefiniti (indicativi, da rifinire guardando le palette).
const List<SeedPreset> seedPresets = [
  SeedPreset('laguna', Color(0xFF3A6EA5)),
  SeedPreset('salvia', Color(0xFF5B8C5A)),
  SeedPreset('terracotta', Color(0xFFC2603A)),
  SeedPreset('ambra', Color(0xFFD49A2A)),
  SeedPreset('lampone', Color(0xFFB03A5B)),
  SeedPreset('lavanda', Color(0xFF7A64B8)),
  SeedPreset('petrolio', Color(0xFF2F7F86)),
  SeedPreset('grafite', Color(0xFF5F6368)),
];

/// Seed usato quando il sistema non fornisce colori dinamici.
const Color fallbackSeed = Color(0xFF3A6EA5);

/// Costruisce lo schema colori secondo le impostazioni.
///
/// Con origine "Sistema", stile Tonale e contrasto standard si usa la
/// palette di Android così com'è; altrimenti il primario del sistema
/// diventa il seed.
ColorScheme buildScheme({
  required SettingsController settings,
  required Brightness brightness,
  ColorScheme? systemScheme,
}) {
  final useSystemAsIs =
      settings.colorSource == ColorSource.system &&
      systemScheme != null &&
      settings.paletteStyle == DynamicSchemeVariant.tonalSpot &&
      settings.contrast == 0;
  if (useSystemAsIs) return systemScheme;

  final seed = switch (settings.colorSource) {
    ColorSource.system => systemScheme?.primary ?? fallbackSeed,
    ColorSource.preset =>
      seedPresets[settings.presetIndex.clamp(0, seedPresets.length - 1)].color,
  };
  return ColorScheme.fromSeed(
    seedColor: seed,
    brightness: brightness,
    dynamicSchemeVariant: settings.paletteStyle,
    contrastLevel: settings.contrast,
  );
}

/// Famiglia di caratteri dell'app (Google Sans del telefono, se c'è).
String? appFontFamily;

ThemeData buildTheme(ColorScheme scheme) {
  final dark = scheme.brightness == Brightness.dark;
  // Stessi toni di GlideColors: card bianche su pagina grigia.
  final card = dark ? scheme.surfaceContainerHigh : scheme.surfaceContainerLow;
  final raised = dark
      ? scheme.surfaceContainerHighest
      : scheme.surfaceContainerHigh;
  final base = ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    fontFamily: appFontFamily,
  );
  return base.copyWith(
    // Il launcher mostra lo sfondo di sistema: le pagine sono trasparenti.
    scaffoldBackgroundColor: Colors.transparent,
    splashFactory: InkSparkle.splashFactory,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
      },
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: card,
      modalBackgroundColor: card,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: raised,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    // Interruttori Android 17: spunta nel cursore quando sono attivi.
    switchTheme: SwitchThemeData(
      thumbIcon: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? const Icon(Icons.check_rounded)
            : null,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        side: WidgetStatePropertyAll(BorderSide(color: scheme.outlineVariant)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant.withValues(alpha: dark ? 0.35 : 0.6),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 24),
    ),
  );
}

final Map<String, ThemeData> _themeCache = {};

/// Tema memorizzato: si ricalcola solo se cambiano colori, stile, contrasto,
/// colori di sistema o carattere.
ThemeData themeFor({
  required SettingsController settings,
  required Brightness brightness,
  ColorScheme? systemScheme,
}) {
  final key = [
    brightness.name,
    settings.colorSource.name,
    settings.presetIndex,
    settings.paletteStyle.name,
    settings.contrast,
    systemScheme?.primary.toARGB32(),
    systemScheme?.tertiary.toARGB32(),
    appFontFamily,
  ].join('|');
  if (_themeCache.length > 8) _themeCache.clear();
  return _themeCache[key] ??= buildTheme(
    buildScheme(
      settings: settings,
      brightness: brightness,
      systemScheme: systemScheme,
    ),
  );
}
