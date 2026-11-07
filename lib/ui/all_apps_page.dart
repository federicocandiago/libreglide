import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_entry.dart';
import '../data/settings.dart';
import 'glide_style.dart';
import 'labels.dart';
import 'scope.dart';
import 'search_page.dart';
import 'widgets/app_actions.dart';
import 'widgets/app_icon.dart';

/// A-Z: "A-Z APPS" bar, groups by letter with a large, thin letter in the
/// first cell, thin dividers, full alphabet on the right.
class AllAppsPage extends StatefulWidget {
  const AllAppsPage({super.key, required this.homeSignal});

  final ValueNotifier<int> homeSignal;

  @override
  State<AllAppsPage> createState() => _AllAppsPageState();
}

class _Section {
  _Section(this.letter, this.apps);
  final String letter;
  final List<AppEntry> apps;
}

const String _alphabet = '#ABCDEFGHIJKLMNOPQRSTUVWXYZ';
const double _railWidth = 26;
const double _listRowExtent = 56;
const double _gridIconSize = 52;
const int _gridColumns = 4;

class _AllAppsPageState extends State<AllAppsPage>
    with AutomaticKeepAliveClientMixin {
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
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  List<_Section> _sections(List<AppEntry> apps) {
    final map = <String, List<AppEntry>>{};
    for (final a in apps) {
      map.putIfAbsent(sectionLetter(a.label), () => []).add(a);
    }
    return [
      for (final ch in _alphabet.split(''))
        if (map[ch] case final list?) _Section(ch, list),
    ];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scope = AppScope.of(context);
    final controller = scope.controller;
    final settings = scope.settings;

    return ListenableBuilder(
      // Only the app list and settings: context changes don't affect the
      // A-Z page.
      listenable: Listenable.merge([controller.appsVersion, settings]),
      builder: (context, _) {
        final grid = settings.allAppsLayout == AllAppsLayout.grid;
        // Height of a grid row: icon + two-line label, with text scaling
        // capped at 115%.
        final scale = MediaQuery.textScalerOf(context)
            .clamp(maxScaleFactor: maxLabelScale)
            .scale(1);
        final gridRowExtent = _gridIconSize + 16 + 6 + 2 * 13 * 1.2 * scale + 6;

        final apps = controller.visibleApps;
        return _Sections(
          header: _Header(
            count: apps.length,
            grid: grid,
            onSearch: () => showGlobalSearch(context),
            onToggleLayout: () => settings.setAllAppsLayout(
              grid ? AllAppsLayout.list : AllAppsLayout.grid,
            ),
          ),
          sections: _sections(apps),
          grid: grid,
          gridRowExtent: gridRowExtent,
          controller: _scroll,
        );
      },
    );
  }
}

/// Thin small-caps header ("A-Z APPS · 87") with search and a grid/list
/// toggle. It is part of the list, so it scrolls away.
class _Header extends StatelessWidget {
  const _Header({
    required this.count,
    required this.grid,
    required this.onSearch,
    required this.onToggleLayout,
  });

  static const double extent = 48;

  final int count;
  final bool grid;
  final VoidCallback onSearch;
  final VoidCallback onToggleLayout;

  @override
  Widget build(BuildContext context) {
    final c = GlideColors.of(context);
    final l = context.l10n;
    Widget action(IconData icon, String tooltip, VoidCallback onTap) =>
        IconButton(
          tooltip: tooltip,
          onPressed: onTap,
          color: c.muted,
          iconSize: 20,
          visualDensity: VisualDensity.compact,
          icon: Icon(icon),
        );
    return SizedBox(
      height: extent,
      child: Padding(
        padding: const EdgeInsets.only(left: cardPadding, right: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${l.azHeader.toUpperCase()}  ·  $count',
                maxLines: 1,
                textScaler: MediaQuery.textScalerOf(context)
                    .clamp(maxScaleFactor: maxLabelScale),
                style: capsStyle(context),
              ),
            ),
            action(Icons.search_rounded, l.searchApps, onSearch),
            action(
              grid ? Icons.view_list_rounded : Icons.grid_view_rounded,
              grid ? l.layoutList : l.layoutGrid,
              onToggleLayout,
            ),
          ],
        ),
      ),
    );
  }
}

/// Grouped list with a letter rail.
class _Sections extends StatelessWidget {
  const _Sections({
    required this.header,
    required this.sections,
    required this.grid,
    required this.gridRowExtent,
    required this.controller,
  });

  final Widget header;
  final List<_Section> sections;
  final bool grid;
  final double gridRowExtent;
  final ScrollController controller;

  double _height(_Section s) => grid
      ? ((s.apps.length + 1) / _gridColumns).ceil() * gridRowExtent + 1
      : (s.apps.length * _listRowExtent).clamp(72.0, double.infinity) + 1;

  @override
  Widget build(BuildContext context) {
    final heights = [for (final s in sections) _height(s)];
    final offsets = <String, double>{};
    var y = _Header.extent;
    for (var i = 0; i < sections.length; i++) {
      offsets[sections[i].letter] = y;
      y += heights[i];
    }
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: _railWidth),
          child: ListView.builder(
            controller: controller,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.only(bottom: bottom + 16),
            itemCount: sections.length + 1,
            itemExtentBuilder: (i, _) => i == 0
                ? _Header.extent
                : (i - 1 < heights.length ? heights[i - 1] : null),
            itemBuilder: (context, i) => i == 0
                ? header
                : grid
                ? _GridSection(
                    section: sections[i - 1],
                    rowExtent: gridRowExtent,
                  )
                : _ListSection(section: sections[i - 1]),
          ),
        ),
        Positioned(
          right: 0,
          top: _Header.extent,
          bottom: bottom + 8,
          width: _railWidth,
          child: _LetterRail(
            available: offsets.keys.toSet(),
            onLetter: (letter) {
              if (!controller.hasClients) return;
              // Letter without apps: jump to the first available one after it.
              final start = _alphabet.indexOf(letter);
              double? target;
              for (var i = start; i < _alphabet.length && target == null; i++) {
                target = offsets[_alphabet[i]];
              }
              target ??= y;
              controller.jumpTo(
                target.clamp(0.0, controller.position.maxScrollExtent),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BigLetter extends StatelessWidget {
  const _BigLetter(this.letter);

  final String letter;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      letter,
      textScaler: TextScaler.noScaling,
      style: TextStyle(
        fontSize: 58,
        fontWeight: FontWeight.w300,
        height: 1,
        color: GlideColors.of(context).accent,
      ),
    ),
  );
}

class _GridSection extends StatelessWidget {
  const _GridSection({required this.section, required this.rowExtent});

  final _Section section;
  final double rowExtent;

  @override
  Widget build(BuildContext context) {
    final c = GlideColors.of(context);
    final cells = <Widget>[
      _BigLetter(section.letter),
      for (final app in section.apps)
        AppTile(app: app, iconSize: _gridIconSize, labelLines: 2),
    ];
    final rows = (cells.length / _gridColumns).ceil();
    return Column(
      children: [
        for (var r = 0; r < rows; r++)
          SizedBox(
            height: rowExtent,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = r * _gridColumns; i < (r + 1) * _gridColumns; i++)
                  Expanded(
                    child: i < cells.length
                        ? (i == 0
                              ? SizedBox(
                                  height: _gridIconSize + 16,
                                  child: cells[i],
                                )
                              : cells[i])
                        : const SizedBox(),
                  ),
              ],
            ),
          ),
        Divider(height: 1, thickness: 0.8, color: c.hairline),
      ],
    );
  }
}

class _ListSection extends StatelessWidget {
  const _ListSection({required this.section});

  final _Section section;

  @override
  Widget build(BuildContext context) {
    final c = GlideColors.of(context);
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 80,
                height: 72,
                child: _BigLetter(section.letter),
              ),
              Expanded(
                child: Column(
                  children: [
                    for (final app in section.apps) _AppListRow(app: app),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, thickness: 0.8, color: c.hairline),
      ],
    );
  }
}

class _AppListRow extends StatelessWidget {
  const _AppListRow({required this.app});

  final AppEntry app;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: _listRowExtent,
    child: InkWell(
      onTap: () => launchFrom(context, app),
      onLongPress: () => showAppActions(context, app),
      child: Row(
        children: [
          AppIconView(app: app, size: 38),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              app.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 17),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Full alphabet on the right, in light grey; the touched letter takes the
/// accent color.
class _LetterRail extends StatefulWidget {
  const _LetterRail({required this.available, required this.onLetter});

  final Set<String> available;
  final ValueChanged<String> onLetter;

  @override
  State<_LetterRail> createState() => _LetterRailState();
}

class _LetterRailState extends State<_LetterRail> {
  String? _active;

  void _select(Offset local, double height) {
    final i = (local.dy / height * _alphabet.length).floor().clamp(
      0,
      _alphabet.length - 1,
    );
    final letter = _alphabet[i];
    if (letter != _active) {
      HapticFeedback.selectionClick();
      setState(() => _active = letter);
      widget.onLetter(letter);
    }
  }

  void _end() => setState(() => _active = null);

  @override
  Widget build(BuildContext context) {
    final c = GlideColors.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _select(d.localPosition, h),
          onTapUp: (_) => _end(),
          onVerticalDragStart: (d) => _select(d.localPosition, h),
          onVerticalDragUpdate: (d) => _select(d.localPosition, h),
          onVerticalDragEnd: (_) => _end(),
          onVerticalDragCancel: _end,
          child: Column(
            children: [
              for (final letter in _alphabet.split(''))
                Expanded(
                  child: Center(
                    child: Text(
                      letter,
                      textScaler: TextScaler.noScaling,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: letter == _active
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: letter == _active
                            ? c.accent
                            : c.muted.withValues(
                                alpha: widget.available.contains(letter)
                                    ? 0.75
                                    : 0.3,
                              ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
