import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/time_context.dart';
import '../core/agenda.dart';
import '../core/space.dart';
import '../core/space_profile.dart';
import '../data/settings.dart';
import 'glide_style.dart';
import 'labels.dart';
import 'scope.dart';
import 'space_cards.dart';
import 'widgets/app_icon.dart';
import 'widgets/context_wallpaper.dart';

/// Space corrente: data sopra lo sfondo, striscia
/// colorata con il nome dello Space, card di azioni e di app.
class SpacePage extends StatefulWidget {
  const SpacePage({super.key});

  @override
  State<SpacePage> createState() => _SpacePageState();
}

class _SpacePageState extends State<SpacePage>
    with AutomaticKeepAliveClientMixin {
  DateTime? _nextAlarm;
  bool? _isDefaultHome;
  StreamSubscription<void>? _resumeSub;

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_resumeSub == null) {
      final bridge = AppScope.of(context).controller.bridge;
      _resumeSub = bridge.resumed.listen((_) => _refresh());
      _refresh();
    }
  }

  @override
  void dispose() {
    _resumeSub?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final bridge = AppScope.of(context).controller.bridge;
    try {
      final alarm = await bridge.nextAlarm();
      final isDefault = await bridge.isDefaultHome();
      if (!mounted) return;
      setState(() {
        _nextAlarm = alarm;
        _isDefaultHome = isDefault;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scope = AppScope.of(context);
    final controller = scope.controller;
    final settings = scope.settings;
    final c = GlideColors.of(context);
    final l = context.l10n;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return ListenableBuilder(
      listenable: Listenable.merge([
        controller,
        settings,
        controller.cards,
        controller.weather,
        controller.places,
      ]),
      builder: (context, _) {
        final kind = controller.currentSpace;
        final apps = controller.suggestions();
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _DateHeader(kind: kind)),
            SliverFillRemaining(
              hasScrollBody: false,
              child: ColoredBox(
                color: c.page,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(0, 0, 0, bottom + cardGap),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: cardGap),
                      if (!_evening(context))
                        _padded(_ActionsCard(actions: _actionsFor(kind))),
                      ..._cards(
                        context,
                        kind,
                        appsCard: (FlatCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              CapsHeader(
                                icon: spaceIcon(kind),
                                label: l.nowAppsHeader,
                              ),
                              if (apps.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    0,
                                    14,
                                    16,
                                  ),
                                  child: Text(
                                    l.learningHint,
                                    style: TextStyle(color: c.muted),
                                  ),
                                )
                              else
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    8,
                                    0,
                                    8,
                                    6,
                                  ),
                                  child: Row(
                                    children: [
                                      for (final app in apps)
                                        Expanded(
                                          child: AppTile(
                                            app: app,
                                            showLabel: false,
                                          ),
                                        ),
                                      for (var i = apps.length; i < 5; i++)
                                        const Expanded(child: SizedBox()),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        )),
                      ),
                      if (_isDefaultHome == false)
                        _padded(
                          _Banner(
                            icon: Icons.home_rounded,
                            text: l.notDefaultBanner,
                            action: l.setAction,
                            onAction: controller.bridge.requestDefaultHome,
                          ),
                        ),
                      if (!settings.infoBannerDismissed)
                        _padded(
                          _Banner(
                            text: l.infoBanner,
                            onAction: settings.dismissInfoBanner,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Azioni rapide dello Space (come in Glide: ognuno ha le sue).
  /// Azioni rapide dello Space, dal suo profilo.
  List<(IconData, String, VoidCallback)> _actionsFor(SpaceKind kind) {
    final controller = AppScope.of(context).controller;
    final bridge = controller.bridge;
    final l = context.l10n;
    final home = controller.places.home;
    final work = controller.places.work;
    final out = <(IconData, String, VoidCallback)>[
      for (final a in profileFor(kind).actions)
        ...switch (a) {
          QuickAction.alarm => [
            (Icons.alarm_rounded, l.actionAlarm, bridge.openAlarms),
          ],
          QuickAction.alarmTomorrow => [
            (Icons.alarm_add_rounded, l.actionAlarmTomorrow, bridge.openAlarms),
          ],
          QuickAction.dnd => [
            (
              Icons.do_not_disturb_on_outlined,
              l.actionDnd,
              bridge.openDoNotDisturb,
            ),
          ],
          QuickAction.newEvent => [
            (Icons.event_rounded, l.newEvent, bridge.newEvent),
          ],
          QuickAction.email => [
            (
              Icons.mail_rounded,
              l.actionEmail,
              () => bridge.openUrl('mailto:'),
            ),
          ],
          QuickAction.maps => [
            (Icons.map_rounded, l.actionMaps, () => bridge.navigateTo('')),
          ],
          QuickAction.toHome => [
            if (home != null)
              (
                Icons.home_rounded,
                l.actionToHome,
                () => bridge.navigateTo('${home.lat},${home.lon}'),
              ),
          ],
          QuickAction.toWork => [
            if (work != null)
              (
                Icons.work_rounded,
                l.actionToWork,
                () => bridge.navigateTo('${work.lat},${work.lon}'),
              ),
          ],
          QuickAction.timer => [
            (Icons.timer_outlined, l.actionTimer, bridge.openTimers),
          ],
          QuickAction.food => [
            (
              Icons.restaurant_rounded,
              l.actionFood,
              () => bridge.navigateTo(l.foodQuery),
            ),
          ],
        },
    ];
    // Senza luoghi noti, "Verso casa/lavoro" lasciano il posto alle mappe.
    if (out.isEmpty) {
      out.add((Icons.map_rounded, l.actionMaps, () => bridge.navigateTo('')));
    }
    return out;
  }

  /// Di sera e di notte, la card Buonanotte prende il posto della sveglia.
  bool _evening(BuildContext context) {
    final scope = AppScope.of(context);
    final slot = scope.controller.currentSlot;
    return scope.settings.eveningCard &&
        (slot == Slot.evening || slot == Slot.night);
  }

  /// Card dello Space: quelle che adesso hanno qualcosa da mostrare,
  /// ordinate dal profilo del momento, dall'uso (le card che tocchi in
  /// questo contesto salgono, e compaiono anche dove il profilo non le
  /// prevede) e dalle scelte "Nascondi / Mostra sempre qui".
  List<Widget> _cards(
    BuildContext context,
    SpaceKind kind, {
    required Widget appsCard,
  }) {
    final scope = AppScope.of(context);
    final settings = scope.settings;
    final controller = scope.controller;
    final cards = controller.cards;
    final profile = profileFor(kind);
    final headphones =
        controller.context.audio == 'headphones' ||
        controller.context.audio == 'bt';
    final destination = settings.nextPlaceCard && cards.events != null
        ? nextDestination(DateTime.now(), cards.events!)
        : null;
    final parking = cards.parking;
    final showParking =
        settings.parkingCard &&
        !controller.driving &&
        (cards.parkingMissing.isNotEmpty ||
            (parking != null &&
                DateTime.now().difference(parking.at) <
                    const Duration(hours: 24)));
    final driving = settings.carCard && controller.driving;
    final agenda = cards.eventsLoaded ? cards.agenda() : null;
    // Agenda vuota: solo dove il profilo la vuole (al mattino); senza
    // permesso resta, per chiederlo.
    final showAgenda =
        settings.agendaCard &&
        cards.eventsLoaded &&
        (agenda == null || agenda.events.isNotEmpty || profile.agendaWhenEmpty);
    final category = profile.category;

    final available = <SpaceCard, Widget>{
      if (driving) SpaceCard.car: CarCard(destination: destination),
      if (showParking) SpaceCard.parking: const ParkingCard(),
      if (_evening(context))
        SpaceCard.evening: EveningCard(nextAlarm: _nextAlarm)
      else if (_nextAlarm != null)
        SpaceCard.alarm: _AlarmCard(time: _nextAlarm!),
      if (settings.mediaCard)
        if (cards.media != null)
          SpaceCard.media: MediaCard(media: cards.media)
        else if (!cards.mediaAccess && headphones)
          SpaceCard.media: const MediaCard(media: null),
      if (settings.travelCard && controller.travelling)
        SpaceCard.travel: const TravelCard(),
      if (destination != null && !driving)
        SpaceCard.nextPlace: NextPlaceCard(event: destination),
      if (showAgenda) SpaceCard.agenda: const AgendaCard(),
      if (settings.weatherCard)
        SpaceCard.weather: WeatherCard(tomorrow: profile.weatherTomorrow),
      SpaceCard.apps: appsCard,
      if (category != null && CategoryAppsCard.hasApps(controller, category))
        SpaceCard.category: CategoryAppsCard(category: category),
      if (settings.screenTime == ScreenTimePlace.space)
        SpaceCard.screenTime: const ScreenTimeCard(),
      if (settings.placesEnabled && controller.places.permission == false)
        SpaceCard.placesInvite: const PlacesInviteCard(),
    };
    final order = arrangeCards(
      profile: profile,
      available: available.keys,
      affinity: controller.cardScores(kind),
      rules: settings.cardRulesFor(kind),
    );
    final invite = order.remove(SpaceCard.placesInvite);
    return [
      for (final card in order)
        _padded(_CardShell(card: card, kind: kind, child: available[card]!)),
      // I widget Android restano in fondo, nell'ordine scelto.
      for (final w in settings.widgets) _padded(AppWidgetCard(widget: w)),
      if (invite) _padded(available[SpaceCard.placesInvite]!),
    ];
  }

  Widget _padded(Widget child) => Padding(
    padding: const EdgeInsets.fromLTRB(cardGap, 0, cardGap, cardGap),
    child: child,
  );
}

/// Giorno e data, centrati sopra lo sfondo del telefono.
class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.kind});

  /// Space corrente, mostrato in una pillola sopra il giorno.
  final SpaceKind kind;

  static const double cardHeight = 168;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final now = DateTime.now();
    final c = GlideColors.of(context);
    const shadow = [Shadow(blurRadius: 10, color: Colors.black54)];
    // La pagina è opaca intorno alla card: lo sfondo (o la foto) si vede
    // solo dentro, così la data resta staccata quando si scorre o si gira
    // pagina.
    return CustomPaint(
      painter: _HolePainter(color: c.page),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(cardGap, cardGap, cardGap, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(cardRadius),
          child: SizedBox(
            height: cardHeight,
            child: Stack(
              children: [
                const Positioned.fill(child: ContextWallpaper()),
                // Velo leggero per leggere la data su qualsiasi sfondo.
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: Color(0x22000000)),
                  ),
                ),
                Positioned.fill(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SpacePill(kind: kind),
                      const SizedBox(height: 12),
                      Text(
                        toBeginningOfSentenceCase(
                          DateFormat.EEEE(locale).format(now),
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w500,
                          shadows: shadow,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat.yMMMMd(locale).format(now),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          shadows: shadow,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dipinge [color] su tutta l'area tranne un rettangolo arrotondato (la card
/// della data), da cui si vede lo sfondo del telefono.
class _HolePainter extends CustomPainter {
  const _HolePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = Path()..addRect(Offset.zero & size);
    final hole = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(cardGap, cardGap, size.width - cardGap, size.height),
          const Radius.circular(cardRadius),
        ),
      );
    canvas.drawPath(
      Path.combine(PathOperation.difference, outer, hole),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_HolePainter old) => old.color != color;
}

/// Pillola con il colore, l'icona e il nome dello Space corrente; al
/// cambio di Space colore e testo sfumano.
class _SpacePill extends StatelessWidget {
  const _SpacePill({required this.kind});

  final SpaceKind kind;

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.of(context).settings;
    final color = GlideColors.of(context).spaceKind(kind);
    final onColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black87;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.fromLTRB(12, 6, 16, 6),
      decoration: ShapeDecoration(
        color: color.withValues(alpha: 0.92),
        shape: const StadiumBorder(),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Row(
          key: ValueKey(kind),
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(spaceIcon(kind), color: onColor, size: 18),
            const SizedBox(width: 8),
            Text(
              spaceLabel(
                context.l10n,
                kind,
                workLabel: settings.workLabel,
              ).toUpperCase(),
              maxLines: 1,
              textScaler: MediaQuery.textScalerOf(context)
                  .clamp(maxScaleFactor: maxLabelScale),
              style: TextStyle(
                color: onColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionsCard extends StatelessWidget {
  const _ActionsCard({required this.actions});

  /// (icona, etichetta, azione), affiancate e separate da linee sottili.
  final List<(IconData, String, VoidCallback)> actions;

  @override
  Widget build(BuildContext context) {
    final c = GlideColors.of(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return FlatCard(
      child: Row(
        children: [
          for (final (i, (icon, label, onTap)) in actions.indexed) ...[
            if (i > 0) Container(width: 0.8, height: 60, color: c.hairline),
            Expanded(
              child: InkWell(
                onTap: onTap,
                child: SizedBox(
                  height: 60,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 22, color: onSurface),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AlarmCard extends StatelessWidget {
  const _AlarmCard({required this.time});

  final DateTime time;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final c = GlideColors.of(context);
    return FlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CapsHeader(icon: Icons.alarm_rounded, label: context.l10n.nextAlarm),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormat.Hm(locale).format(time),
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w400,
                    height: 1,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    toBeginningOfSentenceCase(
                      DateFormat.MMMEd(locale).format(time),
                    ),
                    style: TextStyle(color: c.muted, fontSize: 15),
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

/// Banner in colore d'accento con un pulsante (spunta o azione testuale).
class _Banner extends StatelessWidget {
  const _Banner({
    required this.text,
    required this.onAction,
    this.icon,
    this.action,
  });

  final String text;
  final VoidCallback onAction;
  final IconData? icon;
  final String? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primary,
      borderRadius: BorderRadius.circular(cardRadius),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(cardPadding, 16, 12, 16),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: scheme.onPrimary),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: scheme.onPrimary,
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (action != null)
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(foregroundColor: scheme.onPrimary),
                child: Text(action!.toUpperCase()),
              )
            else
              IconButton(
                onPressed: onAction,
                color: scheme.onPrimary,
                iconSize: 34,
                icon: const Icon(Icons.check_circle_outline_rounded),
              ),
          ],
        ),
      ),
    );
  }
}

/// Involucro di una card dello Space: conta i tocchi (per imparare quali
/// card servono in quale momento) e, tenendola premuta, offre "Nascondi
/// in questo Space" e "Mostra sempre in questo Space".
class _CardShell extends StatefulWidget {
  const _CardShell({
    required this.card,
    required this.kind,
    required this.child,
  });

  final SpaceCard card;
  final SpaceKind kind;
  final Widget child;

  @override
  State<_CardShell> createState() => _CardShellState();
}

class _CardShellState extends State<_CardShell> {
  Offset? _down;
  DateTime? _downAt;

  void _up(PointerUpEvent e) {
    final down = _down;
    final at = _downAt;
    _down = null;
    if (down == null || at == null) return;
    // Un tocco, non uno scorrimento né una pressione lunga.
    if ((e.position - down).distance > 18) return;
    if (DateTime.now().difference(at) > const Duration(milliseconds: 600)) {
      return;
    }
    AppScope.of(context).controller.recordCardUse(widget.card);
  }

  Future<void> _menu() {
    final settings = AppScope.of(context).settings;
    final l = context.l10n;
    final rule = settings.cardRulesFor(widget.kind)[widget.card];
    final space = spaceLabel(l, widget.kind, workLabel: settings.workLabel);
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (sheet) {
        void set(CardRule? r) {
          Navigator.pop(sheet);
          settings.setCardRule(widget.kind, widget.card, r);
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
                child: Text(
                  '${_cardLabel(context, widget.card)} · $space'.toUpperCase(),
                  style: capsStyle(context),
                ),
              ),
              if (rule != CardRule.show)
                ListTile(
                  leading: const Icon(Icons.push_pin_outlined),
                  title: Text(l.cardShowHere),
                  onTap: () => set(CardRule.show),
                ),
              if (rule != CardRule.hide)
                ListTile(
                  leading: const Icon(Icons.visibility_off_outlined),
                  title: Text(l.cardHideHere),
                  onTap: () => set(CardRule.hide),
                ),
              if (rule != null)
                ListTile(
                  leading: const Icon(Icons.auto_awesome_rounded),
                  title: Text(l.cardAuto),
                  onTap: () => set(null),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (e) {
      _down = e.position;
      _downAt = DateTime.now();
    },
    onPointerUp: _up,
    onPointerCancel: (_) => _down = null,
    child: GestureDetector(onLongPress: _menu, child: widget.child),
  );
}

String _cardLabel(BuildContext context, SpaceCard card) {
  final l = context.l10n;
  return switch (card) {
    SpaceCard.car => l.cardCar,
    SpaceCard.parking => l.cardParking,
    SpaceCard.evening => l.cardEvening,
    SpaceCard.alarm => l.actionAlarm,
    SpaceCard.media => l.cardMedia,
    SpaceCard.travel => l.cardTravel,
    SpaceCard.nextPlace => l.cardNextPlace,
    SpaceCard.agenda => l.cardAgenda,
    SpaceCard.weather => l.cardWeather,
    SpaceCard.apps => l.nowAppsHeader,
    SpaceCard.category => l.cardCategory,
    SpaceCard.screenTime => l.screenTime,
    SpaceCard.placesInvite => l.sectionPlaces,
  };
}
