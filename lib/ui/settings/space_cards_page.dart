import 'package:flutter/material.dart';

import '../../core/space.dart';
import '../../core/space_profile.dart';
import '../glide_style.dart';
import '../labels.dart';
import '../scope.dart';
import 'settings_widgets.dart';

/// Card per Space: per ogni Space, quali card mostrare. Automatico segue
/// il profilo del momento e l'uso; Sempre e Mai vincono su entrambi. Da qui
/// si recuperano anche le card che il profilo nasconde (e che quindi non si
/// possono tenere premute sullo Space).
class SpaceCardsListPage extends StatelessWidget {
  const SpaceCardsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.of(context).settings;
    final l = context.l10n;
    final c = GlideColors.of(context);

    Widget group(String title, IconData icon, List<SpaceKind> kinds) =>
        SettingsSection(
          icon: icon,
          title: title,
          children: [
            for (final k in kinds)
              SettingsTile(
                icon: spaceIcon(k),
                title: spaceLabel(l, k, workLabel: settings.workLabel),
                subtitle: _summary(context, k),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SpaceCardsPage(kind: k),
                  ),
                ),
              ),
          ],
        );

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => SettingsScaffold(
        title: l.spaceCards,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: Text(
              l.spaceCardsDesc,
              style: TextStyle(color: c.muted, height: 1.4),
            ),
          ),
          group(l.spacesTime, Icons.schedule_rounded, const [
            SpaceKind.wakeUp,
            SpaceKind.morning,
            SpaceKind.lunch,
            SpaceKind.afternoon,
            SpaceKind.evening,
            SpaceKind.night,
          ]),
          group(l.spacesContext, Icons.explore_rounded, const [
            SpaceKind.home,
            SpaceKind.work,
            SpaceKind.moving,
            SpaceKind.listening,
            SpaceKind.travel,
          ]),
        ],
      ),
    );
  }

  static String _summary(BuildContext context, SpaceKind kind) {
    final l = context.l10n;
    final rules = AppScope.of(context).settings.cardRulesFor(kind);
    if (rules.isEmpty) return l.cardAutoShort;
    return l.spaceCardsCustom(rules.length);
  }
}

/// Le card di uno Space, ciascuna con Automatico / Sempre / Mai.
class SpaceCardsPage extends StatelessWidget {
  const SpaceCardsPage({super.key, required this.kind});

  final SpaceKind kind;

  /// Card che si possono scegliere (l'invito ai luoghi non è una card).
  static const cards = [
    SpaceCard.apps,
    SpaceCard.agenda,
    SpaceCard.weather,
    SpaceCard.category,
    SpaceCard.screenTime,
    SpaceCard.media,
    SpaceCard.nextPlace,
    SpaceCard.travel,
    SpaceCard.evening,
    SpaceCard.alarm,
    SpaceCard.car,
    SpaceCard.parking,
  ];

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.of(context).settings;
    final l = context.l10n;
    final profile = profileFor(kind);
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final rules = settings.cardRulesFor(kind);
        return SettingsScaffold(
          title: spaceLabel(l, kind, workLabel: settings.workLabel),
          children: [
            SettingsSection(
              icon: spaceIcon(kind),
              title: l.spaceCards,
              children: [
                for (final card in cards)
                  SettingsChoiceTile<CardRule?>(
                    icon: spaceCardIcon(card),
                    title: spaceCardLabel(l, card),
                    subtitle: profile.hidden.contains(card)
                        ? l.cardDefaultHidden
                        : l.cardDefaultShown,
                    options: [
                      (null, l.cardAutoShort, null),
                      (CardRule.show, l.cardAlways, null),
                      (CardRule.hide, l.cardNever, null),
                    ],
                    selected: rules[card],
                    onChanged: (r) => settings.setCardRule(kind, card, r),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
