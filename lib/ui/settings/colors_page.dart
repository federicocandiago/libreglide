import 'package:flutter/material.dart';

import '../../core/categories.dart';
import '../../data/settings.dart';
import '../../theme/palette.dart';
import '../glide_style.dart';
import '../labels.dart';
import '../scope.dart';
import 'settings_widgets.dart';

/// Colori: anteprima dal vivo, origine, stile, contrasto, icone a tema
/// (spec-viste-app §6.2).
class ColorsPage extends StatelessWidget {
  const ColorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.of(context).settings;
    final l = context.l10n;

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => SettingsScaffold(
        title: l.colors,
        children: [
          const _Preview(),
          SettingsSection(
            icon: Icons.palette_outlined,
            title: l.colorSource,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 16),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 14,
                  children: [
                    _Swatch(
                      label: l.colorSystem,
                      color: null,
                      selected: settings.colorSource == ColorSource.system,
                      onTap: () => settings.setColorSource(ColorSource.system),
                    ),
                    for (var i = 0; i < seedPresets.length; i++)
                      _Swatch(
                        label: presetLabel(l, seedPresets[i].id),
                        color: seedPresets[i].color,
                        selected:
                            settings.colorSource == ColorSource.preset &&
                            settings.presetIndex == i,
                        onTap: () => settings.setPreset(i),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SettingsSection(
            icon: Icons.style_outlined,
            title: l.paletteStyle,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  cardPadding,
                  0,
                  cardPadding,
                  14,
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final style in paletteStyles)
                      ChoiceChip(
                        label: Text(paletteStyleLabel(l, style)),
                        selected: settings.paletteStyle == style,
                        onSelected: (_) => settings.setPaletteStyle(style),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SettingsSection(
            icon: Icons.tune_rounded,
            title: l.sectionAppearance,
            children: [
              SettingsChoiceTile<double>(
                icon: Icons.contrast_rounded,
                title: l.contrast,
                options: [
                  (0, l.contrastStandard, null),
                  (0.5, l.contrastMedium, null),
                  (1, l.contrastHigh, null),
                ],
                selected: settings.contrast,
                onChanged: settings.setContrast,
              ),
              SettingsSwitchTile(
                icon: Icons.format_color_fill_rounded,
                title: l.themedIcons,
                subtitle: l.themedIconsDesc,
                value: settings.themedIcons,
                onChanged: settings.setThemedIcons,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;

  /// null = colori di sistema.
  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    // Anteprima del seed: tre toni della palette generata.
    final seeded = color == null
        ? null
        : ColorScheme.fromSeed(seedColor: color!, brightness: brightness);

    return SizedBox(
      width: 74,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(cardRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 54,
                height: 54,
                padding: EdgeInsets.all(selected ? 4 : 0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? scheme.primary : Colors.transparent,
                    width: 2.5,
                  ),
                ),
                child: ClipOval(
                  child: seeded == null
                      ? DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: SweepGradient(
                              colors: [
                                scheme.primary,
                                scheme.tertiary,
                                scheme.secondary,
                                scheme.primary,
                              ],
                            ),
                          ),
                          child: Icon(
                            Icons.wallpaper_rounded,
                            size: 22,
                            color: scheme.onPrimary,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: Container(color: seeded.primary)),
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      color: seeded.secondaryContainer,
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      color: seeded.tertiaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textScaler: MediaQuery.textScalerOf(context)
                    .clamp(maxScaleFactor: maxLabelScale),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? scheme.primary : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Anteprima dal vivo: una card delle Collections, la barra delle schede e
/// un banner, con i colori correnti.
class _Preview extends StatelessWidget {
  const _Preview();

  @override
  Widget build(BuildContext context) {
    final c = GlideColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final l = context.l10n;
    final themed = AppScope.of(context).settings.themedIcons;
    const icons = [
      Icons.forum_rounded,
      Icons.photo_camera_rounded,
      Icons.headphones_rounded,
      Icons.explore_rounded,
      Icons.mail_rounded,
    ];

    return FlatCard(
      color: c.page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Barra delle schede in miniatura.
          Container(
            height: 44,
            color: c.card,
            child: Row(
              children: [
                const SizedBox(width: 14),
                for (final (i, w) in <Widget>[
                  Icon(Icons.light_mode_rounded, color: c.muted, size: 20),
                  Text(
                    '09:41',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: scheme.onSurface,
                    ),
                  ),
                  Icon(Icons.apps_rounded, color: c.accent, size: 20),
                  Icon(Icons.sort_by_alpha_rounded, color: c.muted, size: 20),
                ].indexed)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        w,
                        const SizedBox(height: 8),
                        Container(
                          width: 26,
                          height: 3,
                          decoration: BoxDecoration(
                            color: i == 2 ? c.accent : Colors.transparent,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(cardGap),
            child: FlatCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CapsHeader(
                    icon: categoryIcon(AppCategory.messaging),
                    label: categoryLabel(l, AppCategory.messaging),
                    trailing: const Chevron(open: false),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        for (final icon in icons)
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: themed
                                ? scheme.primaryContainer
                                : scheme.surfaceContainerHighest,
                            child: Icon(
                              icon,
                              color: themed
                                  ? scheme.onPrimaryContainer
                                  : scheme.primary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(cardGap, 0, cardGap, cardGap),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(cardRadius),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l.preview,
                      style: TextStyle(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: scheme.onPrimary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
