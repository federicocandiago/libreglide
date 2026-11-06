import 'package:flutter/material.dart';

import '../core/app_entry.dart';
import '../core/categories.dart';
import '../core/collections.dart';
import 'glide_style.dart';
import 'labels.dart';
import 'scope.dart';
import 'widgets/app_icon.dart';

/// Collections: card bianche a tutta larghezza su fondo grigio, con
/// intestazione in maiuscoletto e una riga di icone senza nomi.
/// Toccando l'intestazione la card si apre e mostra tutte le app.
class CollectionsPage extends StatefulWidget {
  const CollectionsPage({super.key, required this.homeSignal});

  final ValueNotifier<int> homeSignal;

  @override
  State<CollectionsPage> createState() => _CollectionsPageState();
}

class _CollectionsPageState extends State<CollectionsPage>
    with AutomaticKeepAliveClientMixin {
  AppCategory? _expanded;
  final _scroll = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    widget.homeSignal.addListener(_reset);
  }

  @override
  void dispose() {
    widget.homeSignal.removeListener(_reset);
    _scroll.dispose();
    super.dispose();
  }

  void _reset() {
    if (_expanded != null) setState(() => _expanded = null);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _toggle(AppCategory c) =>
      setState(() => _expanded = _expanded == c ? null : c);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scope = AppScope.of(context);
    final controller = scope.controller;

    return ListenableBuilder(
      listenable: Listenable.merge([controller, scope.settings]),
      builder: (context, _) {
        final groups = controller.collections;
        if (groups.isEmpty) {
          return Center(child: Text(context.l10n.noCollections));
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            // Icone per riga: una ogni ~72 dp della larghezza utile.
            final usable = constraints.maxWidth - 2 * cardGap - 2 * 8;
            final rowSize = (usable / 72).floor().clamp(4, 6);
            return ListView.builder(
              controller: _scroll,
              padding: EdgeInsets.fromLTRB(
                cardGap,
                cardGap,
                cardGap,
                MediaQuery.paddingOf(context).bottom + cardGap,
              ),
              itemCount: groups.length,
              itemBuilder: (context, i) {
                final g = groups[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: cardGap),
                  child: CollectionCard(
                    key: ValueKey(g.category),
                    group: g,
                    rowSize: rowSize,
                    expanded: _expanded == g.category,
                    onToggle: () => _toggle(g.category),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class CollectionCard extends StatelessWidget {
  const CollectionCard({
    super.key,
    required this.group,
    required this.rowSize,
    required this.expanded,
    required this.onToggle,
  });

  final CollectionGroup group;
  final int rowSize;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final c = GlideColors.of(context);
    final l = context.l10n;
    final row = group.row(rowSize);
    final rest = group.rest(rowSize);

    return FlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CapsHeader(
            icon: categoryIcon(group.category),
            label: categoryLabel(l, group.category),
            // Si apre solo se ci sono app oltre la riga visibile.
            onTap: rest.isEmpty ? null : onToggle,
            onLongPress: () => _showCategoryActions(context, group),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (group.pinned)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.push_pin_rounded,
                      size: 16,
                      color: c.accent,
                    ),
                  ),
                if (rest.isNotEmpty) Chevron(open: expanded),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
            child: _IconRow(
              apps: row,
              columns: rowSize,
              labels: AppScope.of(context).settings.collectionLabels,
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: expanded && rest.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                    child: Column(
                      children: [
                        Divider(height: 9, color: c.hairline),
                        for (var i = 0; i < rest.length; i += rowSize)
                          _IconRow(
                            apps: rest.sublist(
                              i,
                              (i + rowSize).clamp(0, rest.length),
                            ),
                            columns: rowSize,
                            labels: true,
                          ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _IconRow extends StatelessWidget {
  const _IconRow({
    required this.apps,
    required this.columns,
    required this.labels,
  });

  final List<AppEntry> apps;
  final int columns;
  final bool labels;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final app in apps)
        Expanded(
          child: AppTile(app: app, iconSize: 50, showLabel: labels),
        ),
      for (var i = apps.length; i < columns; i++)
        const Expanded(child: SizedBox()),
    ],
  );
}

Future<void> _showCategoryActions(BuildContext context, CollectionGroup group) {
  final settings = AppScope.of(context).settings;
  final l = context.l10n;
  final messenger = ScaffoldMessenger.maybeOf(context);
  final c = group.category;

  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(categoryIcon(c)),
            title: Text(
              categoryLabel(l, c).toUpperCase(),
              style: capsStyle(sheetContext, size: 15),
            ),
          ),
          const Divider(indent: 24, endIndent: 24),
          ListTile(
            leading: Icon(
              group.pinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
            ),
            title: Text(group.pinned ? l.unpinCategory : l.pinCategory),
            onTap: () {
              Navigator.pop(sheetContext);
              settings.setPinned(c, !group.pinned);
            },
          ),
          ListTile(
            leading: const Icon(Icons.visibility_off_rounded),
            title: Text(l.hideCategory),
            onTap: () {
              Navigator.pop(sheetContext);
              settings.setCategoryHidden(c, true);
              messenger?.showSnackBar(
                SnackBar(
                  content: Text(l.categoryHidden),
                  action: SnackBarAction(
                    label: l.undo,
                    onPressed: () => settings.setCategoryHidden(c, false),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
