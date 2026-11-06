/// Componenti delle schermate di impostazione, nello stile di Glide:
/// barra con titolo in maiuscoletto, sezioni in card piatte con
/// intestazione, righe separate da linee sottili. Tocchi Material You:
/// icone su fondo tonale, switch e selettori della palette.
library;

import 'package:flutter/material.dart';

import '../glide_style.dart';

/// Pagina di impostazioni: barra in alto e sezioni su fondo grigio.
class SettingsScaffold extends StatelessWidget {
  const SettingsScaffold({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = GlideColors.of(context);
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: c.page,
      body: Column(
        children: [
          Material(
            color: c.card,
            child: Container(
              height: top + 60,
              padding: EdgeInsets.only(top: top, left: 4, right: 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    color: c.muted,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textScaler: MediaQuery.textScalerOf(context)
                          .clamp(maxScaleFactor: maxLabelScale),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.6,
                        color: c.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                cardGap,
                cardGap,
                cardGap,
                bottom + 24,
              ),
              children: [
                for (final child in children)
                  Padding(
                    padding: const EdgeInsets.only(bottom: cardGap),
                    child: child,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sezione: card piatta con intestazione in maiuscoletto e righe separate.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = GlideColors.of(context);
    return FlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CapsHeader(icon: icon, label: title),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 72,
                endIndent: cardPadding,
                color: c.hairline,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Icona su fondo tonale (tocco Material You).
class TonalIcon extends StatelessWidget {
  const TonalIcon(this.icon, {super.key, this.danger = false});

  final IconData icon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: danger ? scheme.errorContainer : scheme.secondaryContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 20,
        color: danger ? scheme.onErrorContainer : scheme.onSecondaryContainer,
      ),
    );
  }
}

/// Riga: icona tonale, titolo, sottotitolo facoltativo, elemento a destra.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = GlideColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(cardPadding, 12, 12, 12),
        child: Row(
          children: [
            TonalIcon(icon, danger: danger),
            const SizedBox(width: cardPadding),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: danger ? scheme.error : scheme.onSurface,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.3,
                        color: c.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 10), trailing!],
          ],
        ),
      ),
    );
  }
}

/// Riga con interruttore; tutta la riga lo attiva.
class SettingsSwitchTile extends StatelessWidget {
  const SettingsSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SettingsTile(
    icon: icon,
    title: title,
    subtitle: subtitle,
    onTap: () => onChanged(!value),
    trailing: Switch(value: value, onChanged: onChanged),
  );
}

/// Scelta tra poche opzioni: titolo sopra, selettore a tutta larghezza
/// sotto, così le etichette non vanno mai a capo.
class SettingsChoiceTile<T> extends StatelessWidget {
  const SettingsChoiceTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// Valore → (etichetta, icona facoltativa).
  final List<(T, String, IconData?)> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsTile(icon: icon, title: title, subtitle: subtitle),
          Padding(
            padding: const EdgeInsets.fromLTRB(cardPadding, 0, cardPadding, 0),
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.1,
              child: SegmentedButton<T>(
                showSelectedIcon: false,
                style: const ButtonStyle(
                  visualDensity: VisualDensity(vertical: -1),
                ),
                segments: [
                  for (final (value, label, icon) in options)
                    ButtonSegment<T>(
                      value: value,
                      label: Text(label, maxLines: 1, softWrap: false),
                      icon: icon == null ? null : Icon(icon, size: 18),
                    ),
                ],
                selected: {selected},
                onSelectionChanged: (s) => onChanged(s.first),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
