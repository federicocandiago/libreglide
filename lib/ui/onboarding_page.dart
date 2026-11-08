import 'package:flutter/material.dart';

import '../core/categories.dart';
import '../core/time_context.dart';
import 'glide_style.dart';
import 'labels.dart';
import 'scope.dart';
import 'settings/legal_pages.dart';
import 'widgets/logo.dart';

/// Shows the onboarding in a near-fullscreen modal, with Home and its
/// wallpaper visible around it.
Future<void> showOnboarding(BuildContext context, {bool dismissible = true}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'onboarding',
    barrierColor: Colors.black38,
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (dialogContext, _, _) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 20, 12, 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(sheetRadius),
          child: OnboardingPage(
            dismissible: dismissible,
            onDone: () => Navigator.of(dialogContext).pop(),
          ),
        ),
      ),
    ),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween(begin: 0.94, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// First-run onboarding: welcome, how it works, privacy, favorite
/// collections (initial boost), final touches.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    required this.onDone,
    this.dismissible = true,
  });

  final VoidCallback onDone;

  /// Can be dismissed with "back" (not on first run).
  final bool dismissible;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const _steps = 4;
  final _pages = PageController();
  int _step = 0;
  final List<AppCategory> _chosen = [];
  bool _prefillDock = true;
  bool? _isDefaultHome;
  bool _initialized = false;

  /// Re-checks the default Home when the user comes back from the system
  /// dialog or settings.
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _checkDefault);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Runs once: AppScope notifies often, and re-running would refill the
    // categories the user deselected and query the bridge every time.
    if (_initialized) return;
    _initialized = true;
    _chosen.addAll(AppScope.of(context).controller.favoriteCategories);
    _checkDefault();
  }

  Future<void> _checkDefault() async {
    if (!mounted) return;
    final bridge = AppScope.of(context).controller.bridge;
    try {
      final v = await bridge.isDefaultHome();
      if (mounted) setState(() => _isDefaultHome = v);
    } catch (_) {}
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _pages.dispose();
    super.dispose();
  }

  void _go(int step) {
    _pages.animateToPage(
      step,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    final scope = AppScope.of(context);
    final controller = scope.controller;
    final settings = scope.settings;
    await controller.setFavoriteCategories(_chosen);
    if (_prefillDock && settings.favorites.isEmpty) {
      for (final app in controller.suggestedDock()) {
        settings.setFavorite(app.id, true);
      }
    }
    settings.setOnboardingDone(true);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final c = GlideColors.of(context);
    final l = context.l10n;
    final last = _step == _steps - 1;

    // On first run "back" doesn't close it; from settings it does.
    return PopScope(
      canPop: widget.dismissible,
      child: Material(
        color: c.page,
        child: SafeArea(
          top: false,
          bottom: false,
          child: Column(
            children: [
              // Top bar, like the other screens: logo, name, step.
              Container(
                color: c.card,
                padding: const EdgeInsets.fromLTRB(cardPadding, 14, 20, 14),
                child: Row(
                  children: [
                    const LibreGlideLogo(size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'LIBREGLIDE',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.6,
                          color: c.muted,
                        ),
                      ),
                    ),
                    Text('${_step + 1} / $_steps', style: capsStyle(context)),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pages,
                  onPageChanged: (i) => setState(() => _step = i),
                  children: [
                    const _Welcome(),
                    const _Intro(),
                    _Collections(
                      chosen: _chosen,
                      onToggle: (cat) => setState(
                        () => _chosen.contains(cat)
                            ? _chosen.remove(cat)
                            : _chosen.add(cat),
                      ),
                    ),
                    _Finish(
                      prefillDock: _prefillDock,
                      onPrefillDock: (v) => setState(() => _prefillDock = v),
                      isDefaultHome: _isDefaultHome,
                      onSetDefault: () async {
                        await AppScope.of(context).controller.bridge
                            .requestDefaultHome();
                        await _checkDefault();
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 16, 16),
                child: Row(
                  children: [
                    if (_step > 0)
                      TextButton(
                        onPressed: () => _go(_step - 1),
                        child: Text(l.obBack),
                      )
                    else
                      const SizedBox(width: 64),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < _steps; i++)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: i == _step ? 18 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: i == _step ? c.accent : c.hairline,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: last ? _finish : () => _go(_step + 1),
                      child: Text(
                        last ? l.obFinish : (_step == 0 ? l.obStart : l.obNext),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared layout: title, text, card.
class _Step extends StatelessWidget {
  const _Step({required this.title, this.text, required this.child});

  final String title;
  final String? text;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = GlideColors.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(cardGap, 22, cardGap, 12),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w500,
              height: 1.2,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        if (text != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              text!,
              style: TextStyle(fontSize: 15.5, height: 1.45, color: c.muted),
            ),
          ),
        ],
        const SizedBox(height: 18),
        child,
      ],
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome();

  @override
  Widget build(BuildContext context) {
    final c = GlideColors.of(context);
    final l = context.l10n;
    // Spaces drawn as on the Space page: rounded strips with icon, separator
    // and name.
    return _Step(
      title: l.obWelcomeTitle,
      text: l.obWelcomeText,
      child: Column(
        children: [
          for (final slot in [Slot.wakeUp, Slot.afternoon, Slot.evening])
            Container(
              height: 56,
              margin: const EdgeInsets.only(bottom: cardGap),
              decoration: BoxDecoration(
                color: c.space(slot),
                borderRadius: BorderRadius.circular(cardRadius),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 58,
                    child: Icon(slotIcon(slot), color: Colors.white),
                  ),
                  Container(width: 1, height: 56, color: Colors.white38),
                  const SizedBox(width: 16),
                  Text(
                    slotLabel(l, slot).toUpperCase(),
                    style: thinTitleStyle(color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(cardPadding, 10, cardPadding, 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 21, color: scheme.onSecondaryContainer),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// How it works and privacy, in a single step.
class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = GlideColors.of(context);
    Widget divider() => Divider(height: 1, indent: 72, color: c.hairline);
    return _Step(
      title: l.obHowTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FlatCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CapsHeader(icon: Icons.touch_app_rounded, label: l.obHowTitle),
                _Bullet(icon: Icons.wb_sunny_rounded, text: l.obHowSpace),
                divider(),
                _Bullet(icon: Icons.schedule_rounded, text: l.obHowHome),
                divider(),
                _Bullet(icon: Icons.table_rows_rounded, text: l.obHowCollections),
                divider(),
                _Bullet(
                  icon: Icons.swipe_vertical_rounded,
                  text: l.obHowSearch,
                ),
                divider(),
                _Bullet(icon: Icons.menu_rounded, text: l.obHowDrawer),
                divider(),
                _Bullet(icon: Icons.beach_access_rounded, text: l.obHowDetox),
                const SizedBox(height: 4),
              ],
            ),
          ),
          const SizedBox(height: cardGap),
          FlatCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CapsHeader(
                  icon: Icons.verified_user_rounded,
                  label: l.obPrivacyTitle,
                ),
                _Bullet(icon: Icons.no_accounts_rounded, text: l.obPrivacy1),
                divider(),
                _Bullet(icon: Icons.phone_android_rounded, text: l.obPrivacy2),
                divider(),
                _Bullet(icon: Icons.cloud_off_rounded, text: l.obPrivacy3),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const PrivacyPolicyPage(),
                        ),
                      ),
                      icon: const Icon(Icons.article_outlined),
                      label: Text(l.obReadPolicy),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Collections extends StatelessWidget {
  const _Collections({required this.chosen, required this.onToggle});

  final List<AppCategory> chosen;
  final ValueChanged<AppCategory> onToggle;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).controller;
    final l = context.l10n;
    final c = GlideColors.of(context);
    final scheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        // The 8 most populated categories on the phone (excluding System and
        // Other).
        final counts = <AppCategory, int>{};
        for (final a in controller.visibleApps) {
          final cat = controller.categoryOf(a);
          if (cat == AppCategory.system || cat == AppCategory.other) continue;
          counts[cat] = (counts[cat] ?? 0) + 1;
        }
        final top = counts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final cats = top.take(8).toList();

        return _Step(
          title: l.obCollectionsTitle,
          text: l.obCollectionsText,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!controller.loaded)
                const Center(child: CircularProgressIndicator())
              else
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: cardGap,
                  crossAxisSpacing: cardGap,
                  childAspectRatio: 2.0,
                  children: [
                    for (final e in cats)
                      _CategoryChoice(
                        category: e.key,
                        count: e.value,
                        order: chosen.indexOf(e.key),
                        onTap: () => onToggle(e.key),
                      ),
                  ],
                ),
              const SizedBox(height: 14),
              Text(
                l.obCollectionsHint,
                style: TextStyle(color: c.muted, fontSize: 13.5),
              ),
              if (chosen.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  chosen.map((cat) => categoryLabel(l, cat)).join(' · '),
                  style: TextStyle(color: scheme.primary, fontSize: 13.5),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _CategoryChoice extends StatelessWidget {
  const _CategoryChoice({
    required this.category,
    required this.count,
    required this.order,
    required this.onTap,
  });

  final AppCategory category;
  final int count;

  /// Position in the selection (0 = first), -1 if not selected.
  final int order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = GlideColors.of(context);
    final l = context.l10n;
    final selected = order >= 0;
    return Material(
      color: selected ? scheme.primaryContainer : c.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(innerRadius),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(innerRadius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(
                categoryIcon(category),
                color: selected ? scheme.onPrimaryContainer : c.accent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryLabel(l, category),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textScaler: MediaQuery.textScalerOf(context)
                          .clamp(maxScaleFactor: maxLabelScale),
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.15,
                        fontWeight: FontWeight.w600,
                        color: selected ? scheme.onPrimaryContainer : null,
                      ),
                    ),
                    Text(
                      l.appCount(count),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: selected ? scheme.onPrimaryContainer : c.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                CircleAvatar(
                  radius: 11,
                  backgroundColor: scheme.primary,
                  child: Text(
                    '${order + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: scheme.onPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Finish extends StatelessWidget {
  const _Finish({
    required this.prefillDock,
    required this.onPrefillDock,
    required this.isDefaultHome,
    required this.onSetDefault,
  });

  final bool prefillDock;
  final ValueChanged<bool> onPrefillDock;
  final bool? isDefaultHome;
  final VoidCallback onSetDefault;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = GlideColors.of(context);
    return _Step(
      title: l.obFinishTitle,
      child: FlatCard(
        child: Column(
          children: [
            ListTile(
              leading: Icon(
                isDefaultHome == true
                    ? Icons.check_circle_rounded
                    : Icons.home_rounded,
                color: c.accent,
              ),
              title: Text(isDefaultHome == true ? l.isDefault : l.setDefault),
              onTap: isDefaultHome == true ? null : onSetDefault,
            ),
            Divider(height: 1, indent: 16, endIndent: 16, color: c.hairline),
            SwitchListTile(
              secondary: Icon(Icons.dock_rounded, color: c.accent),
              title: Text(l.obDockPrefill),
              value: prefillDock,
              onChanged: onPrefillDock,
            ),
          ],
        ),
      ),
    );
  }
}
