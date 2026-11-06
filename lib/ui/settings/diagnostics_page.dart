import 'package:flutter/material.dart';

import '../glide_style.dart';
import '../labels.dart';
import '../scope.dart';
import '../widgets/app_icon.dart';
import 'settings_widgets.dart';

/// Diagnostica: contesto corrente e motivazione delle previsioni
/// (spec-motore-contesto §10).
class DiagnosticsPage extends StatelessWidget {
  const DiagnosticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).controller;
    final l = context.l10n;
    final c = GlideColors.of(context);
    final mono = TextStyle(
      fontFamily: 'monospace',
      fontSize: 12,
      height: 1.4,
      color: c.muted,
    );
    final ctx = controller.context;
    final top = controller.suggestions(n: 10);

    return SettingsScaffold(
      title: l.diagnostics,
      children: [
        SettingsSection(
          icon: slotIcon(ctx.slot),
          title: l.currentContext,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final e in ctx.toMap().entries)
                    Text('${e.key}: ${e.value ?? '—'}', style: mono),
                  const SizedBox(height: 8),
                  Text(
                    l.launchesCount(controller.predictor.totalLaunches),
                    style: TextStyle(color: c.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
        SettingsSection(
          icon: Icons.home_work_outlined,
          title: l.sectionPlaces,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'space: ${controller.currentSpace.name} · '
                    'luogo: ${controller.places.current?.id ?? '—'} · '
                    'viaggio: ${controller.travelling}',
                    style: mono,
                  ),
                  for (final p in controller.places.engine.places)
                    Text(
                      '#${p.id} ${p.effectiveRole.name}'
                      '${p.userRole != null ? ' (utente)' : ''} '
                      'casa ${((controller.places.engine.scores[p.id]?.homeConfidence ?? 0) * 100).round()}% '
                      'lavoro ${((controller.places.engine.scores[p.id]?.workConfidence ?? 0) * 100).round()}% '
                      'giorni ${controller.places.engine.scores[p.id]?.days ?? 0} '
                      'wifi ${p.wifiHits.length}',
                      style: mono,
                    ),
                ],
              ),
            ),
          ],
        ),
        SettingsSection(
          icon: Icons.insights_rounded,
          title: l.predictions,
          children: [
            if (top.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(l.noPredictions, style: TextStyle(color: c.muted)),
              )
            else
              for (final app in top)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    cardPadding,
                    8,
                    cardPadding,
                    8,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppIconView(app: app, size: 36),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              app.label,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              controller.explain(app).join('\n'),
                              style: mono,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ],
    );
  }
}
