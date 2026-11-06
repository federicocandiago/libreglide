import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_entry.dart';
import '../core/categories.dart';
import '../core/search.dart';
import 'glide_style.dart';
import 'labels.dart';
import 'scope.dart';
import 'widgets/app_actions.dart';
import 'widgets/app_icon.dart';

/// Apre la ricerca globale scendendo dall'alto, con la tastiera già pronta.
Future<void> showGlobalSearch(BuildContext context) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, _, _) => const GlobalSearchPage(),
      transitionsBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, -0.08),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}

/// Ricerca globale: barra in alto (già attiva), poi le app consigliate per
/// questo momento, poi i risultati come elenco; senza testo si possono
/// sfogliare le raccolte.
class GlobalSearchPage extends StatefulWidget {
  const GlobalSearchPage({super.key});

  @override
  State<GlobalSearchPage> createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends State<GlobalSearchPage> {
  final _text = TextEditingController();
  String _query = '';
  AppCategory? _category;
  Map<String, double>? _scores;
  Timer? _autoLaunch;
  bool _launching = false;

  /// Pausa prima dell'avvio automatico: evita di aprire un'app mentre si
  /// sta ancora scrivendo.
  static const _autoLaunchDelay = Duration(milliseconds: 350);

  @override
  void initState() {
    super.initState();
    _text.addListener(_onText);
  }

  @override
  void dispose() {
    _autoLaunch?.cancel();
    _text.dispose();
    super.dispose();
  }

  String? _hitsQuery;
  List<SearchHit> _hitsCache = const [];

  /// Risultati per [query], calcolati una volta per testo.
  List<SearchHit> _hits(String query) {
    if (query == _hitsQuery) return _hitsCache;
    _hitsQuery = query;
    return _hitsCache = _computeHits(query);
  }

  List<SearchHit> _computeHits(String query) {
    final controller = AppScope.of(context).controller;
    final l = context.l10n;
    _scores ??= controller.searchScores();
    return searchApps(
      controller.visibleApps,
      query,
      score: _scores!,
      categoryLabel: (a) => categoryLabel(l, controller.categoryOf(a)),
    );
  }

  void _onText() {
    if (_text.text == _query) return;
    setState(() {
      _query = _text.text;
      if (_query.isNotEmpty) _category = null;
    });
    _autoLaunch?.cancel();
    final settings = AppScope.of(context).settings;
    final q = _query.trim();
    if (!settings.autoLaunchSingle || q.length < 2) return;
    final hits = _hits(q);
    if (hits.length != 1) return;
    final app = hits.single.app;
    _autoLaunch = Timer(_autoLaunchDelay, () {
      if (!mounted || _text.text.trim() != q) return;
      _launch(app);
    });
  }

  void _launch(AppEntry app, [BuildContext? tileContext]) {
    if (_launching) return;
    _launching = true;
    final controller = AppScope.of(context).controller;
    final navigator = Navigator.of(context);
    controller.launch(
      app,
      bounds: tileContext == null ? null : boundsOf(tileContext),
    );
    // Chiude la ricerca dopo l'animazione di apertura: tornando al launcher
    // si ritrova la schermata di partenza.
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      if (mounted) navigator.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final controller = scope.controller;
    final settings = scope.settings;
    final c = GlideColors.of(context);
    final l = context.l10n;
    final top = controller.topForSearch(settings.searchTopApps);
    final q = _query.trim();

    final List<AppEntry> results;
    if (q.isNotEmpty) {
      results = [for (final h in _hits(q)) h.app];
    } else if (_category != null) {
      results = [
        for (final a in controller.visibleApps)
          if (controller.categoryOf(a) == _category) a,
      ];
    } else {
      results = const [];
    }

    return Scaffold(
      backgroundColor: c.page,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(cardGap, cardGap, cardGap, 0),
              child: PillSearchField(
                controller: _text,
                hint: l.searchHint,
                autofocus: true,
                onSubmitted: () {
                  if (results.isNotEmpty) _launch(results.first);
                },
                onClose: () => Navigator.of(context).pop(),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  cardGap,
                  cardGap,
                  cardGap,
                  MediaQuery.paddingOf(context).bottom + cardGap,
                ),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  if (top.isNotEmpty)
                    FlatCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CapsHeader(
                            icon: slotIcon(controller.context.slot),
                            label: l.nowAppsHeader,
                          ),
                          for (var r = 0; r < top.length; r += 4)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(6, 0, 6, 2),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (var i = r; i < r + 4; i++)
                                    Expanded(
                                      child: i < top.length
                                          ? _AppCell(
                                              app: top[i],
                                              onLaunch: _launch,
                                            )
                                          : const SizedBox(),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: cardGap),
                  if (q.isEmpty && _category == null)
                    _BrowseCollections(
                      onPick: (cat) => setState(() => _category = cat),
                    )
                  else
                    _ResultsCard(
                      results: results,
                      category: _category,
                      onClearCategory: () => setState(() => _category = null),
                      onLaunch: _launch,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Icona con nome, per le app consigliate.
class _AppCell extends StatelessWidget {
  const _AppCell({required this.app, required this.onLaunch});

  final AppEntry app;
  final void Function(AppEntry, BuildContext) onLaunch;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(cardRadius),
    onTap: () => onLaunch(app, context),
    onLongPress: () => showAppActions(context, app),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      child: Column(
        children: [
          AppIconView(app: app, size: 50),
          const SizedBox(height: 6),
          Text(
            app.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            textScaler: MediaQuery.textScalerOf(context)
                .clamp(maxScaleFactor: maxLabelScale),
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    ),
  );
}

/// Senza testo: le raccolte come chip da sfogliare.
class _BrowseCollections extends StatelessWidget {
  const _BrowseCollections({required this.onPick});

  final ValueChanged<AppCategory> onPick;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).controller;
    final l = context.l10n;
    final c = GlideColors.of(context);
    final groups = controller.collections;
    return FlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CapsHeader(icon: Icons.apps_rounded, label: l.searchCollections),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final g in groups)
                  ActionChip(
                    avatar: Icon(categoryIcon(g.category), color: c.accent),
                    label: Text(
                      '${categoryLabel(l, g.category)} · ${g.ranked.length}',
                    ),
                    onPressed: () => onPick(g.category),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsCard extends StatelessWidget {
  const _ResultsCard({
    required this.results,
    required this.category,
    required this.onClearCategory,
    required this.onLaunch,
  });

  final List<AppEntry> results;
  final AppCategory? category;
  final VoidCallback onClearCategory;
  final void Function(AppEntry, BuildContext) onLaunch;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).controller;
    final c = GlideColors.of(context);
    final l = context.l10n;
    return FlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CapsHeader(
            icon: category == null
                ? Icons.search_rounded
                : categoryIcon(category!),
            label: category == null
                ? l.resultsCount(results.length)
                : categoryLabel(l, category!),
            trailing: category == null
                ? null
                : IconButton(
                    visualDensity: VisualDensity.compact,
                    color: c.muted,
                    onPressed: onClearCategory,
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
          if (results.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              child: Text(l.noResults, style: TextStyle(color: c.muted)),
            )
          else
            for (final (i, app) in results.indexed) ...[
              if (i > 0) Divider(height: 1, indent: 66, color: c.hairline),
              _ResultRow(
                app: app,
                category: categoryLabel(l, controller.categoryOf(app)),
                onLaunch: onLaunch,
              ),
            ],
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.app,
    required this.category,
    required this.onLaunch,
  });

  final AppEntry app;
  final String category;
  final void Function(AppEntry, BuildContext) onLaunch;

  @override
  Widget build(BuildContext context) {
    final c = GlideColors.of(context);
    return InkWell(
      onTap: () => onLaunch(app, context),
      onLongPress: () => showAppActions(context, app),
      child: SizedBox(
        height: 58,
        child: Row(
          children: [
            const SizedBox(width: 14),
            AppIconView(app: app, size: 38),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                app.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: cardPadding, left: 8),
              child: Text(
                category.toUpperCase(),
                textScaler: MediaQuery.textScalerOf(context)
                    .clamp(maxScaleFactor: maxLabelScale),
                style: capsStyle(context, size: 10, color: c.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
