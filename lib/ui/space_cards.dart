/// Card dinamiche dello Space: Agenda e In ascolto.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../core/agenda.dart';
import '../core/app_entry.dart';
import '../core/categories.dart';
import '../core/weather.dart';
import '../l10n/gen/app_localizations.dart';
import '../platform/launcher_bridge.dart';
import 'glide_style.dart';
import 'labels.dart';
import 'scope.dart';
import 'widgets/app_icon.dart';

/// Agenda: impegni di oggi (o di domani, di sera) con barra colorata, ora,
/// titolo e indicazioni per il luogo. Senza permesso, invito a concederlo.
class AgendaCard extends StatelessWidget {
  const AgendaCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).controller;
    final cards = controller.cards;
    final bridge = controller.bridge;
    final l = context.l10n;
    final c = GlideColors.of(context);
    final view = cards.agenda();

    if (view == null) {
      return FlatCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CapsHeader(icon: Icons.event_rounded, label: l.cardAgenda),
            _PermissionBody(
              text: l.agendaPermission,
              onAllow: bridge.requestCalendar,
            ),
          ],
        ),
      );
    }

    final tomorrow = view.day == AgendaDay.tomorrow;
    return FlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CapsHeader(
            icon: Icons.event_rounded,
            label: tomorrow ? l.agendaTomorrow : l.agendaToday,
            trailing: IconButton(
              tooltip: l.newEvent,
              visualDensity: VisualDensity.compact,
              color: c.muted,
              onPressed: bridge.newEvent,
              icon: const Icon(Icons.add_rounded),
            ),
          ),
          if (view.events.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
              child: Center(
                child: Text(
                  (tomorrow ? l.noEventsTomorrow : l.noEventsToday)
                      .toUpperCase(),
                  style: capsStyle(context, size: 12),
                ),
              ),
            )
          else ...[
            for (final e in view.events)
              _EventRow(
                event: e,
                onOpen: () => bridge.openEvent(e),
                onNavigate: e.location == null
                    ? null
                    : () => bridge.navigateTo(e.location!),
              ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event, required this.onOpen, this.onNavigate});

  final CalendarEvent event;
  final VoidCallback onOpen;
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context) {
    final c = GlideColors.of(context);
    final l = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final color = event.color == null ? c.accent : Color(event.color!);
    final time = event.allDay
        ? l.allDay
        : DateFormat.Hm(locale).format(event.begin);

    return InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(cardPadding, 6, 6, 6),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 64,
              child: Text(
                time,
                maxLines: 2,
                textScaler: MediaQuery.textScalerOf(context)
                    .clamp(maxScaleFactor: maxLabelScale),
                style: TextStyle(
                  fontSize: event.allDay ? 12 : 15,
                  fontWeight: FontWeight.w600,
                  color: c.muted,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title.isEmpty ? '—' : event.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (event.location != null)
                    Text(
                      event.location!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: c.muted),
                    ),
                ],
              ),
            ),
            if (onNavigate != null)
              IconButton(
                tooltip: l.navigate,
                color: c.muted,
                onPressed: onNavigate,
                icon: const Icon(Icons.near_me_rounded),
              )
            else
              const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

/// In ascolto: copertina, titolo, artista e controlli. Senza accesso ai
/// media, se sono collegate le cuffie, invito a concederlo.
class MediaCard extends StatelessWidget {
  const MediaCard({super.key, required this.media});

  /// null = accesso mancante (mostra l'invito).
  final MediaInfo? media;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).controller;
    final cards = controller.cards;
    final l = context.l10n;
    final c = GlideColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final m = media;

    if (m == null) {
      return FlatCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CapsHeader(icon: Icons.headphones_rounded, label: l.nowPlaying),
            _PermissionBody(
              text: l.mediaPermission,
              onAllow: controller.bridge.openMediaAccess,
            ),
          ],
        ),
      );
    }

    final app = controller.byPackage(m.package);
    void openPlayer() {
      if (app != null) launchFrom(context, app);
    }

    return FlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CapsHeader(
            icon: Icons.headphones_rounded,
            label: l.nowPlaying,
            onTap: openPlayer,
            trailing: app == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: AppIconView(app: app, size: 22),
                  ),
          ),
          InkWell(
            onTap: openPlayer,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                cardPadding,
                0,
                cardPadding,
                4,
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: m.art != null
                          ? Image.memory(
                              m.art!,
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                            )
                          : ColoredBox(
                              color: scheme.secondaryContainer,
                              child: Icon(
                                Icons.music_note_rounded,
                                color: scheme.onSecondaryContainer,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                        if (m.artist != null && m.artist!.isNotEmpty)
                          Text(
                            m.artist!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 14, color: c.muted),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: l.previous,
                  iconSize: 30,
                  color: c.muted,
                  onPressed: m.canPrevious
                      ? () => cards.mediaCommand('previous')
                      : null,
                  icon: const Icon(Icons.skip_previous_rounded),
                ),
                const SizedBox(width: 18),
                IconButton.filledTonal(
                  tooltip: m.playing ? l.pause : l.play,
                  iconSize: 34,
                  onPressed: () => cards.mediaCommand('playPause'),
                  icon: Icon(
                    m.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  ),
                ),
                const SizedBox(width: 18),
                IconButton(
                  tooltip: l.next,
                  iconSize: 30,
                  color: c.muted,
                  onPressed: m.canNext
                      ? () => cards.mediaCommand('next')
                      : null,
                  icon: const Icon(Icons.skip_next_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Testo e pulsante "Consenti" per le card che richiedono un permesso.
class _PermissionBody extends StatelessWidget {
  const _PermissionBody({
    required this.text,
    required this.onAllow,
    this.allowLabel,
    this.onDismiss,
    this.dismissLabel,
  });

  final String text;
  final VoidCallback onAllow;
  final String? allowLabel;
  final VoidCallback? onDismiss;
  final String? dismissLabel;

  @override
  Widget build(BuildContext context) {
    final c = GlideColors.of(context);
    final allow = FilledButton.tonal(
      onPressed: onAllow,
      child: Text(allowLabel ?? context.l10n.allow),
    );
    final body = Text(
      text,
      style: TextStyle(fontSize: 14, height: 1.35, color: c.muted),
    );
    if (onDismiss == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 10, 10),
        child: Row(
          children: [
            Expanded(child: body),
            const SizedBox(width: 8),
            allow,
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          body,
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: onDismiss, child: Text(dismissLabel ?? '')),
              const SizedBox(width: 4),
              allow,
            ],
          ),
        ],
      ),
    );
  }
}

/// Riga di icone delle app di una categoria (le più probabili adesso).
class _CategoryApps extends StatelessWidget {
  const _CategoryApps({required this.category});

  final AppCategory category;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).controller;
    final group = controller.collections
        .where((g) => g.category == category)
        .firstOrNull;
    final apps = group?.row(4) ?? const <AppEntry>[];
    if (apps.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
      child: Row(
        children: [
          for (final app in apps)
            Expanded(child: AppTile(app: app, iconSize: 44, showLabel: false)),
          for (var i = apps.length; i < 4; i++)
            const Expanded(child: SizedBox()),
        ],
      ),
    );
  }
}

/// Buonanotte: sveglia di domani, Non disturbare, promemoria di ricarica.
class EveningCard extends StatelessWidget {
  const EveningCard({super.key, required this.nextAlarm});

  final DateTime? nextAlarm;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).controller;
    final bridge = controller.bridge;
    final l = context.l10n;
    final c = GlideColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final level = controller.batteryLevel;
    final lowBattery = level != null && level < 40 && !controller.charging;

    Widget row({
      required IconData icon,
      required Widget child,
      VoidCallback? onTap,
      Color? color,
    }) => InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          children: [
            Icon(icon, color: color ?? c.muted),
            const SizedBox(width: 16),
            Expanded(child: child),
          ],
        ),
      ),
    );

    return FlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CapsHeader(icon: Icons.bedtime_rounded, label: l.cardEvening),
          row(
            icon: Icons.alarm_rounded,
            onTap: bridge.openAlarms,
            child: nextAlarm == null
                ? Text(l.noAlarm, style: TextStyle(color: c.muted))
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat.Hm(locale).format(nextAlarm!),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w400,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          toBeginningOfSentenceCase(
                            DateFormat.MMMEd(locale).format(nextAlarm!),
                          ),
                          style: TextStyle(color: c.muted),
                        ),
                      ),
                    ],
                  ),
          ),
          Divider(height: 1, indent: 56, color: c.hairline),
          row(
            icon: Icons.do_not_disturb_on_outlined,
            color: controller.doNotDisturb ? c.accent : null,
            onTap: bridge.openDoNotDisturb,
            child: Text(
              controller.doNotDisturb ? l.dndOn : l.actionDnd,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: controller.doNotDisturb
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ),
          if (lowBattery) ...[
            Divider(height: 1, indent: 56, color: c.hairline),
            row(
              icon: Icons.battery_alert_rounded,
              color: scheme.error,
              child: Text(l.chargeReminder(level)),
            ),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

/// Prossima destinazione: impegno con un luogo nelle prossime ore,
/// indicazioni con un tocco e app di mappe.
class NextPlaceCard extends StatelessWidget {
  const NextPlaceCard({super.key, required this.event});

  final CalendarEvent event;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).controller;
    final l = context.l10n;
    final c = GlideColors.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    return FlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CapsHeader(icon: Icons.near_me_rounded, label: l.cardNextPlace),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.location!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${DateFormat.Hm(locale).format(event.begin)} · '
                        '${event.title}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: c.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed: () =>
                      controller.bridge.navigateTo(event.location!),
                  icon: const Icon(Icons.directions_rounded),
                  label: Text(l.navigate),
                ),
              ],
            ),
          ),
          const _CategoryApps(category: AppCategory.maps),
        ],
      ),
    );
  }
}

/// In viaggio: ora di casa, app di viaggio, "Ora vivo qui".
class TravelCard extends StatelessWidget {
  const TravelCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).controller;
    final l = context.l10n;
    final c = GlideColors.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final home = controller.homeTime;
    return FlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CapsHeader(
            icon: Icons.flight_takeoff_rounded,
            label: l.cardTravel,
            trailing: TextButton(
              onPressed: controller.setHomeHere,
              child: Text(l.travelHere),
            ),
          ),
          if (home != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.home_rounded, color: c.muted),
                  const SizedBox(width: 12),
                  Text(
                    l.homeTime(DateFormat.Hm(locale).format(home)),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    controller.settings.homeTimeZone ?? '',
                    style: TextStyle(color: c.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          const _CategoryApps(category: AppCategory.maps),
        ],
      ),
    );
  }
}

/// Vista nativa di un widget Android, alla larghezza disponibile.
class AppWidgetHostView extends StatelessWidget {
  const AppWidgetHostView({super.key, required this.widget});

  final PlacedWidget widget;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: widget.height,
    child: LayoutBuilder(
      builder: (context, constraints) => AndroidView(
        key: ValueKey('appwidget-${widget.id}'),
        viewType: 'libreglide/appwidget',
        creationParams: {
          'id': widget.id,
          'width': constraints.maxWidth,
          'height': widget.height,
        },
        creationParamsCodec: const StandardMessageCodec(),
      ),
    ),
  );
}

/// Widget Android a tutta larghezza, dentro una card dello Space.
class AppWidgetCard extends StatelessWidget {
  const AppWidgetCard({super.key, required this.widget});

  final PlacedWidget widget;

  @override
  Widget build(BuildContext context) =>
      FlatCard(child: AppWidgetHostView(widget: widget));
}

/// Simbolo della condizione meteo (versione notte per il sereno).
IconData weatherIcon(WeatherKind k, {bool isDay = true}) => switch (k) {
  WeatherKind.clear =>
    isDay ? Icons.wb_sunny_outlined : Icons.nightlight_outlined,
  WeatherKind.partly =>
    isDay ? Icons.wb_cloudy_outlined : Icons.nights_stay_outlined,
  WeatherKind.cloudy => Icons.cloud_outlined,
  WeatherKind.fog => Icons.foggy,
  WeatherKind.drizzle => Icons.grain_rounded,
  WeatherKind.rain => Icons.water_drop_outlined,
  WeatherKind.snow => Icons.ac_unit_rounded,
  WeatherKind.showers => Icons.umbrella_outlined,
  WeatherKind.storm => Icons.thunderstorm_outlined,
};

String weatherLabel(L10n l, WeatherKind k) => switch (k) {
  WeatherKind.clear => l.weatherClear,
  WeatherKind.partly => l.weatherPartly,
  WeatherKind.cloudy => l.weatherCloudy,
  WeatherKind.fog => l.weatherFog,
  WeatherKind.drizzle => l.weatherDrizzle,
  WeatherKind.rain => l.weatherRain,
  WeatherKind.snow => l.weatherSnow,
  WeatherKind.showers => l.weatherShowers,
  WeatherKind.storm => l.weatherStorm,
};

/// Meteo, come in Glide: temperatura grande e sottile, simbolo, massima e
/// minima con barrette colorate; sotto le prossime ore.
class WeatherCard extends StatelessWidget {
  const WeatherCard({super.key});

  @override
  Widget build(BuildContext context) {
    final weather = AppScope.of(context).controller.weather;
    final l = context.l10n;
    final c = GlideColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final w = weather.weather;

    if (weather.permission == false) {
      return FlatCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CapsHeader(icon: Icons.wb_sunny_outlined, label: l.cardWeather),
            _PermissionBody(
              text: l.weatherPermission,
              onAllow: weather.requestPermission,
            ),
          ],
        ),
      );
    }
    if (w == null) return const SizedBox();

    final locale = Localizations.localeOf(context).toLanguageTag();
    String deg(double v) => '${v.round()}°';
    Widget bar(Color color) => Container(
      width: 4,
      height: 16,
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );

    return FlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CapsHeader(icon: Icons.place_outlined, label: l.weatherHere),
          Padding(
            padding: const EdgeInsets.fromLTRB(cardPadding, 0, cardPadding, 8),
            child: Row(
              children: [
                Icon(
                  weatherIcon(w.kind, isDay: w.isDay),
                  size: 48,
                  color: c.accent,
                ),
                const SizedBox(width: 18),
                Text(
                  deg(w.temperature),
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.w300,
                    height: 1,
                    color: scheme.onSurface,
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      weatherLabel(l, w.kind),
                      style: TextStyle(color: c.muted, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        bar(const Color(0xFFE5735C)),
                        Text(
                          deg(w.max),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 10),
                        bar(const Color(0xFF4A9BE0)),
                        Text(
                          deg(w.min),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (w.hours.isNotEmpty) ...[
            Divider(height: 1, indent: 16, endIndent: 16, color: c.hairline),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
              child: Row(
                children: [
                  for (final h in w.hours)
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            DateFormat.Hm(locale).format(h.time),
                            style: TextStyle(color: c.muted, fontSize: 12.5),
                          ),
                          const SizedBox(height: 4),
                          Icon(
                            weatherIcon(
                              h.kind,
                              isDay: h.time.hour >= 7 && h.time.hour < 19,
                            ),
                            size: 22,
                            color: c.muted,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            deg(h.temperature),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (h.rainChance >= 20)
                            Text(
                              '${h.rainChance}%',
                              style: TextStyle(
                                color: const Color(0xFF4A9BE0),
                                fontSize: 11.5,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
            child: Text(
              l.weatherSource,
              textAlign: TextAlign.end,
              style: TextStyle(color: c.muted, fontSize: 10.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// In auto: prossima destinazione, mappe e musica a portata di pollice.
class CarCard extends StatelessWidget {
  const CarCard({super.key, this.destination});

  final CalendarEvent? destination;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).controller;
    final l = context.l10n;
    final c = GlideColors.of(context);
    final d = destination;
    return FlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CapsHeader(icon: Icons.directions_car_rounded, label: l.cardCar),
          if (d != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      d.location!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => controller.bridge.navigateTo(d.location!),
                    icon: const Icon(Icons.directions_rounded),
                    label: Text(l.navigate),
                  ),
                ],
              ),
            ),
          const _CategoryApps(category: AppCategory.maps),
          Divider(height: 1, indent: 16, endIndent: 16, color: c.hairline),
          const SizedBox(height: 4),
          const _CategoryApps(category: AppCategory.music),
        ],
      ),
    );
  }
}

/// "3 h 12 min" oppure "45 min".
String formatDuration(L10n l, Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  return h > 0 ? l.durationHM(h, m) : l.durationM(m);
}

/// Apre il Benessere digitale se c'è, altrimenti l'accesso ai dati d'uso.
void _openWellbeing(BuildContext context) {
  final controller = AppScope.of(context).controller;
  final app = controller.byPackage('com.google.android.apps.wellbeing');
  if (app != null) {
    launchFrom(context, app);
  } else {
    controller.bridge.openUsageAccess();
  }
}

/// Pillola sulla Home con il tempo di utilizzo di oggi (come in Olauncher).
class ScreenTimePill extends StatelessWidget {
  const ScreenTimePill({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = AppScope.of(context).controller.cards;
    final l = context.l10n;
    return ListenableBuilder(
      listenable: cards,
      builder: (context, _) {
        final t = cards.screenTime;
        final label = t == null
            ? l.screenTime
            : '${l.screenTimeToday} · ${formatDuration(l, t.total)}';
        return Material(
          color: Colors.black.withValues(alpha: 0.35),
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: () => t == null
                ? AppScope.of(context).controller.bridge.openUsageAccess()
                : _openWellbeing(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.hourglass_bottom_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Card del tempo di utilizzo: totale e le app più usate oggi.
class ScreenTimeCard extends StatelessWidget {
  const ScreenTimeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).controller;
    final cards = controller.cards;
    final l = context.l10n;
    final c = GlideColors.of(context);
    final t = cards.screenTime;

    if (cards.usageAccess == false) {
      return FlatCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CapsHeader(
              icon: Icons.hourglass_bottom_rounded,
              label: l.screenTime,
            ),
            _PermissionBody(
              text: l.screenTimePermission,
              onAllow: controller.bridge.openUsageAccess,
            ),
          ],
        ),
      );
    }
    if (t == null) return const SizedBox();
    final top = [
      for (final (pkg, d) in t.top)
        if (controller.byPackage(pkg) case final app?) (app, d),
    ].take(3).toList();
    final longest = top.isEmpty ? 1 : top.first.$2.inSeconds.clamp(1, 1 << 30);

    return FlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CapsHeader(
            icon: Icons.hourglass_bottom_rounded,
            label: l.screenTime,
            onTap: () => _openWellbeing(context),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(cardPadding, 0, cardPadding, 8),
            child: Text(
              formatDuration(l, t.total),
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w400,
                height: 1.1,
              ),
            ),
          ),
          for (final (app, d) in top)
            InkWell(
              onTap: () => launchFrom(context, app),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  cardPadding,
                  6,
                  cardPadding,
                  6,
                ),
                child: Row(
                  children: [
                    AppIconView(app: app, size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  app.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                formatDuration(l, d),
                                style: TextStyle(color: c.muted, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: d.inSeconds / longest,
                              minHeight: 5,
                              backgroundColor: c.raised,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Invito a concedere la posizione precisa per riconoscere casa e lavoro.
class PlacesInviteCard extends StatelessWidget {
  const PlacesInviteCard({super.key});

  @override
  Widget build(BuildContext context) {
    final places = AppScope.of(context).controller.places;
    final l = context.l10n;
    return FlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CapsHeader(icon: Icons.home_work_rounded, label: l.placesEnabled),
          _PermissionBody(
            text: l.placesPermission,
            onAllow: places.requestPermission,
          ),
        ],
      ),
    );
  }
}

/// "Dove ho parcheggiato": punto salvato allo scollegamento dall'auto,
/// indicazioni per tornarci, "Dimentica". Se mancano permessi, li chiede
/// uno alla volta.
class ParkingCard extends StatelessWidget {
  const ParkingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).controller;
    final cards = controller.cards;
    final l = context.l10n;
    final c = GlideColors.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final missing = cards.parkingMissing.firstOrNull;
    final p = cards.parking;

    if (missing != null) {
      return FlatCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CapsHeader(icon: Icons.local_parking_rounded, label: l.cardParking),
            _PermissionBody(
              text: switch (missing) {
                'bluetooth' => l.parkingNeedsBluetooth,
                'precise' => l.parkingNeedsPrecise,
                _ when cards.parkingBlocked => l.parkingBackgroundBlocked,
                _ => l.parkingNeedsBackground,
              },
              allowLabel: cards.parkingBlocked ? l.openSettings : null,
              onAllow: cards.requestNextParkingPermission,
              // Senza il permesso la funzione non può andare: si spegne
              // invece di lasciare la richiesta lì per sempre.
              onDismiss: () =>
                  AppScope.of(context).settings.setParkingCard(false),
              dismissLabel: l.turnOff,
            ),
          ],
        ),
      );
    }
    if (p == null) return const SizedBox();
    final age = DateTime.now().difference(p.at);
    final ago = age.inMinutes < 60
        ? l.agoMinutes(age.inMinutes)
        : l.agoHours(age.inHours);

    return FlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CapsHeader(
            icon: Icons.local_parking_rounded,
            label: l.cardParking,
            trailing: TextButton(
              onPressed: cards.forgetParking,
              child: Text(l.forget),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(cardPadding, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.parkedAt(DateFormat.Hm(locale).format(p.at), ago),
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (!p.precise || p.accuracy > 50)
                        Text(
                          l.parkedImprecise(p.accuracy.round()),
                          style: TextStyle(color: c.muted, fontSize: 13),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed: () =>
                      controller.bridge.navigateTo('${p.lat},${p.lon}'),
                  icon: const Icon(Icons.directions_walk_rounded),
                  label: Text(l.navigate),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
