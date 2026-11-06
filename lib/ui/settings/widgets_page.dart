import 'package:flutter/material.dart';

import '../../data/settings.dart';
import '../../platform/launcher_bridge.dart';
import '../glide_style.dart';
import '../labels.dart';
import '../scope.dart';
import '../widgets/app_icon.dart';
import 'settings_widgets.dart';

/// Widget Android nello Space: elenco, altezza, ordine, aggiunta.
class WidgetsPage extends StatelessWidget {
  const WidgetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final settings = scope.settings;
    final controller = scope.controller;
    final l = context.l10n;
    final c = GlideColors.of(context);

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => SettingsScaffold(
        title: l.cardWidgets,
        children: [
          SettingsSection(
            icon: Icons.widgets_outlined,
            title: l.cardWidgets,
            children: [
              if (settings.widgets.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(l.noWidgets, style: TextStyle(color: c.muted)),
                )
              else
                for (final (i, w) in settings.widgets.indexed)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                    child: Row(
                      children: [
                        if (controller.byPackage(w.package) case final app?)
                          AppIconView(app: app, size: 36)
                        else
                          const Icon(Icons.widgets_rounded, size: 36),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                w.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${l.widgetHeight}: ${w.height.round()} dp',
                                style: TextStyle(color: c.muted, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: l.widgetShorter,
                          onPressed: w.height <= 90
                              ? null
                              : () =>
                                    settings.resizeWidget(w.id, w.height - 40),
                          icon: const Icon(Icons.unfold_less_rounded),
                        ),
                        IconButton(
                          tooltip: l.widgetTaller,
                          onPressed: w.height >= 480
                              ? null
                              : () =>
                                    settings.resizeWidget(w.id, w.height + 40),
                          icon: const Icon(Icons.unfold_more_rounded),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (v) async {
                            switch (v) {
                              case 'up':
                                settings.moveWidget(w.id, -1);
                              case 'down':
                                settings.moveWidget(w.id, 1);
                              case 'remove':
                                await controller.bridge.removeWidget(w.id);
                                settings.removeWidget(w.id);
                            }
                          },
                          itemBuilder: (_) => [
                            if (i > 0)
                              PopupMenuItem(value: 'up', child: Text(l.moveUp)),
                            if (i < settings.widgets.length - 1)
                              PopupMenuItem(
                                value: 'down',
                                child: Text(l.moveDown),
                              ),
                            PopupMenuItem(
                              value: 'remove',
                              child: Text(l.remove),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              SettingsTile(
                icon: Icons.add_rounded,
                title: l.addWidget,
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const WidgetProvidersPage(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Widget installati, raggruppati per app.
class WidgetProvidersPage extends StatefulWidget {
  const WidgetProvidersPage({super.key, this.home = false});

  /// Destinazione: Home (righe da 88 dp, max 3) o Space.
  final bool home;

  @override
  State<WidgetProvidersPage> createState() => _WidgetProvidersPageState();
}

class _WidgetProvidersPageState extends State<WidgetProvidersPage> {
  Future<List<WidgetProvider>>? _providers;
  bool _adding = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _providers ??= AppScope.of(context).controller.bridge.widgetProviders();
  }

  Future<void> _add(WidgetProvider p) async {
    if (_adding) return;
    setState(() => _adding = true);
    final scope = AppScope.of(context);
    final navigator = Navigator.of(context);
    final placed = await scope.controller.bridge.addWidget(p);
    if (!mounted) return;
    setState(() => _adding = false);
    if (placed != null) {
      if (widget.home) {
        // Sulla Home l'altezza va a righe intere, da 1 a 4.
        const row = SettingsController.homeRowHeight;
        final rows = (placed.height / row).ceil().clamp(1, 4);
        scope.settings.addWidget(placed.withHeight(rows * row), home: true);
      } else {
        scope.settings.addWidget(placed);
      }
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).controller;
    final l = context.l10n;
    return FutureBuilder<List<WidgetProvider>>(
      future: _providers,
      builder: (context, snap) {
        final byPackage = <String, List<WidgetProvider>>{};
        for (final p in snap.data ?? const <WidgetProvider>[]) {
          byPackage.putIfAbsent(p.package, () => []).add(p);
        }
        final packages = byPackage.keys.toList()
          ..sort((a, b) {
            final la = controller.byPackage(a)?.sortKey ?? a;
            final lb = controller.byPackage(b)?.sortKey ?? b;
            return la.compareTo(lb);
          });
        return SettingsScaffold(
          title: l.addWidget,
          children: [
            if (snap.data == null || _adding)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              for (final pkg in packages)
                SettingsSection(
                  icon: Icons.widgets_outlined,
                  title: controller.byPackage(pkg)?.label ?? pkg,
                  children: [
                    for (final p in byPackage[pkg]!)
                      InkWell(
                        onTap: () => _add(p),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                          child: Row(
                            children: [
                              if (controller.byPackage(pkg) case final app?)
                                AppIconView(app: app, size: 36)
                              else
                                const Icon(Icons.widgets_rounded, size: 36),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.label,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      l.widgetMinSize(p.minWidth, p.minHeight),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: GlideColors.of(context).muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.add_rounded),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
          ],
        );
      },
    );
  }
}
