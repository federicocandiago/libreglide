import 'package:flutter/material.dart';

import '../../app_info.dart';
import '../../core/places.dart';
import '../../core/wallpaper_moment.dart';
import '../../data/settings.dart';
import '../../net/unsplash.dart';
import '../../state/wallpaper_controller.dart';
import '../glide_style.dart';
import '../labels.dart';
import '../scope.dart';
import 'colors_page.dart';
import 'detox_page.dart';
import 'diagnostics_page.dart';
import '../onboarding_page.dart';
import 'hidden_page.dart';
import 'legal_pages.dart';
import 'settings_widgets.dart';
import 'space_cards_page.dart';
import 'widgets_page.dart';
import '../widgets/logo.dart';

/// UI languages, each written in its own language.
const Map<String, String> languageNames = {
  'it': 'Italiano',
  'en': 'English',
  'es': 'Español',
  'de': 'Deutsch',
  'fr': 'Français',
};

/// Settings sub-pages, in the order of [_sections].
enum _Section {
  appearance,
  wallpaper,
  places,
  space,
  search,
  apps,
  language,
  launcher,
  data,
}

/// Settings (spec-viste-app §6–§7): a main page with grouped entries, as in
/// Android 17; each entry opens its own sub-page.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final settings = scope.settings;
    final controller = scope.controller;
    final l = context.l10n;
    const chevron = Icon(Icons.chevron_right_rounded);

    void open(_Section section, String title) => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _SettingsSubPage(section: section, title: title),
      ),
    );

    Widget entry(
      _Section section,
      IconData icon,
      String title,
      String? summary,
    ) => SettingsTile(
      icon: icon,
      title: title,
      subtitle: summary,
      trailing: chevron,
      onTap: () => open(section, title),
    );

    String onOff(bool v) => v ? l.stateOn : l.stateOff;

    return ListenableBuilder(
      listenable: Listenable.merge([settings, controller]),
      builder: (context, _) {
        final activeCards = [
          settings.agendaCard,
          settings.mediaCard,
          settings.eveningCard,
          settings.nextPlaceCard,
          settings.travelCard,
          settings.weatherCard,
          settings.carCard,
          settings.parkingCard,
        ].where((v) => v).length;
        return SettingsScaffold(
          title: l.settingsTitle,
          children: [
            SettingsSection(
              icon: Icons.palette_outlined,
              title: l.groupLook,
              children: [
                entry(
                  _Section.appearance,
                  Icons.palette_rounded,
                  l.sectionAppearance,
                  switch (settings.themeMode) {
                    ThemeMode.system => l.themeSystem,
                    ThemeMode.light => l.themeLight,
                    ThemeMode.dark => l.themeDark,
                  },
                ),
                entry(
                  _Section.wallpaper,
                  Icons.wallpaper_rounded,
                  l.sectionWallpaper,
                  onOff(settings.dailyWallpaper || settings.contextWallpaper),
                ),
                entry(
                  _Section.space,
                  Icons.dashboard_customize_rounded,
                  l.sectionSpace,
                  l.cardsActive(activeCards),
                ),
              ],
            ),
            SettingsSection(
              icon: Icons.tune_rounded,
              title: l.groupBehavior,
              children: [
                entry(
                  _Section.places,
                  Icons.home_work_rounded,
                  l.sectionPlaces,
                  onOff(settings.placesEnabled),
                ),
                entry(
                  _Section.search,
                  Icons.swipe_vertical_rounded,
                  l.sectionSearchGestures,
                  null,
                ),
                entry(
                  _Section.apps,
                  Icons.apps_rounded,
                  l.sectionApps,
                  settings.allAppsLayout == AllAppsLayout.grid
                      ? l.layoutGrid
                      : l.layoutList,
                ),
                SettingsTile(
                  icon: Icons.beach_access_rounded,
                  title: l.detoxTitle,
                  subtitle: settings.detoxEnabled
                      ? l.detoxAppsCount(settings.detoxApps.length)
                      : l.stateOff,
                  trailing: chevron,
                  onTap: () => openDetox(context),
                ),
              ],
            ),
            SettingsSection(
              icon: Icons.settings_outlined,
              title: l.groupSystem,
              children: [
                entry(
                  _Section.language,
                  Icons.translate_rounded,
                  l.sectionLanguage,
                  settings.locale == null
                      ? l.languageSystemShort
                      : languageNames[settings.locale!.languageCode] ??
                            l.languageSystemShort,
                ),
                entry(
                  _Section.launcher,
                  Icons.home_rounded,
                  l.sectionLauncher,
                  null,
                ),
                entry(
                  _Section.data,
                  Icons.shield_rounded,
                  l.sectionData,
                  l.launchesCount(controller.predictor.totalLaunches),
                ),
                SettingsTile(
                  icon: Icons.info_rounded,
                  title: l.sectionAbout,
                  subtitle: l.version(appVersion),
                  trailing: chevron,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const AboutPage()),
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

/// Developer command: the sub-page with the given name (e.g. `places`).
Widget? settingsSubPageFor(BuildContext context, String name) {
  final section = _Section.values.where((e) => e.name == name).firstOrNull;
  if (section == null) return null;
  return _SettingsSubPage(section: section, title: name.toUpperCase());
}

/// A sub-page: the matching settings section.
class _SettingsSubPage extends StatelessWidget {
  const _SettingsSubPage({required this.section, required this.title});

  final _Section section;
  final String title;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([scope.settings, scope.controller]),
      builder: (context, _) => SettingsScaffold(
        title: title,
        children: [_sections(context)[section.index]],
      ),
    );
  }
}

/// About: black-and-white logo, version, privacy policy, licenses,
/// introduction.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = GlideColors.of(context);
    const chevron = Icon(Icons.chevron_right_rounded);
    void open(Widget page) =>
        Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => page));
    return SettingsScaffold(
      title: l.sectionAbout,
      children: [
        FlatCard(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              cardPadding,
              28,
              cardPadding,
              24,
            ),
            child: Column(
              children: [
                LibreGlideLogo(size: 120, monochrome: true, background: c.card),
                const SizedBox(height: 16),
                Text(
                  'LIBREGLIDE',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2.4,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(l.version(appVersion), style: TextStyle(color: c.muted)),
                const SizedBox(height: 10),
                Text(
                  l.aboutDesc,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.muted, height: 1.4),
                ),
              ],
            ),
          ),
        ),
        SettingsSection(
          icon: Icons.info_outline_rounded,
          title: l.sectionAbout,
          children: [
            SettingsTile(
              icon: Icons.policy_rounded,
              title: l.privacyPolicy,
              subtitle: l.privacyPolicyDesc,
              trailing: chevron,
              onTap: () => open(const PrivacyPolicyPage()),
            ),
            SettingsTile(
              icon: Icons.code_rounded,
              title: l.openSource,
              subtitle: l.openSourceDesc,
              trailing: chevron,
              onTap: () => open(const OpenSourcePage()),
            ),
            SettingsTile(
              icon: Icons.slideshow_rounded,
              title: l.showOnboarding,
              trailing: chevron,
              onTap: () => showOnboarding(context),
            ),
          ],
        ),
      ],
    );
  }
}

/// The settings sections, in the order of [_Section].
List<Widget> _sections(BuildContext context) {
  final scope = AppScope.of(context);
  final settings = scope.settings;
  final controller = scope.controller;
  final l = context.l10n;

  void open(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  const chevron = Icon(Icons.chevron_right_rounded);

  return [
    SettingsSection(
      icon: Icons.palette_outlined,
      title: l.sectionAppearance,
      children: [
        SettingsChoiceTile<ThemeMode>(
          icon: Icons.contrast_rounded,
          title: l.theme,
          options: [
            (ThemeMode.system, l.themeSystem, null),
            (ThemeMode.light, l.themeLight, null),
            (ThemeMode.dark, l.themeDark, null),
          ],
          selected: settings.themeMode,
          onChanged: settings.setThemeMode,
        ),
        SettingsTile(
          icon: Icons.palette_rounded,
          title: l.colors,
          subtitle: settings.colorSource == ColorSource.system
              ? l.colorSystemDesc
              : l.colorPreset,
          trailing: chevron,
          onTap: () => open(const ColorsPage()),
        ),
        SettingsChoiceTile<DockStyle>(
          icon: Icons.dock_rounded,
          title: l.dockStyle,
          options: [
            (DockStyle.tray, l.dockTray, Icons.call_to_action_rounded),
            (
              DockStyle.transparent,
              l.dockTransparent,
              Icons.blur_linear_rounded,
            ),
          ],
          selected: settings.dockStyle,
          onChanged: settings.setDockStyle,
        ),
        SettingsChoiceTile<HomeTabLabel>(
          icon: Icons.today_rounded,
          title: l.homeTabLabel,
          subtitle: settings.weatherCard ? null : l.homeTabWeatherOff,
          options: [
            (HomeTabLabel.date, l.homeTabDate, Icons.calendar_today_rounded),
            (HomeTabLabel.weather, l.homeTabWeather, Icons.wb_sunny_outlined),
          ],
          disabled: {if (!settings.weatherCard) HomeTabLabel.weather},
          // Without the Weather card the tab shows the date anyway.
          selected: settings.weatherCard
              ? settings.homeTabLabel
              : HomeTabLabel.date,
          onChanged: settings.setHomeTabLabel,
        ),
        SettingsSwitchTile(
          icon: Icons.rounded_corner_rounded,
          title: l.homeCorners,
          subtitle: l.homeCornersDesc,
          value: settings.homeCorners,
          onChanged: settings.setHomeCorners,
        ),
        SettingsSwitchTile(
          icon: Icons.screen_lock_portrait_rounded,
          title: l.lockPortrait,
          subtitle: l.lockPortraitDesc,
          value: settings.lockPortrait,
          onChanged: settings.setLockPortrait,
        ),
        SettingsSwitchTile(
          icon: Icons.blur_on_rounded,
          title: l.frostedGlass,
          subtitle: l.frostedGlassDesc,
          value: settings.frostedGlass,
          onChanged: settings.setFrostedGlass,
        ),
        SettingsSwitchTile(
          icon: Icons.format_color_fill_rounded,
          title: l.themedIcons,
          subtitle: l.themedIconsDesc,
          value: settings.themedIcons,
          onChanged: settings.setThemedIcons,
        ),
      ],
    ),
    const _WallpaperSection(),
    const _PlacesSection(),
    SettingsSection(
      icon: Icons.dashboard_customize_outlined,
      title: l.sectionSpace,
      children: [
        SettingsTile(
          icon: Icons.tune_rounded,
          title: l.spaceCards,
          subtitle: l.spaceCardsEntryDesc,
          trailing: chevron,
          onTap: () => open(const SpaceCardsListPage()),
        ),
        SettingsSwitchTile(
          icon: Icons.event_rounded,
          title: l.cardAgenda,
          subtitle: l.cardAgendaDesc,
          value: settings.agendaCard,
          onChanged: settings.setAgendaCard,
        ),
        SettingsSwitchTile(
          icon: Icons.headphones_rounded,
          title: l.cardMedia,
          subtitle: l.cardMediaDesc,
          value: settings.mediaCard,
          onChanged: settings.setMediaCard,
        ),
        SettingsSwitchTile(
          icon: Icons.bedtime_rounded,
          title: l.cardEvening,
          subtitle: l.cardEveningDesc,
          value: settings.eveningCard,
          onChanged: settings.setEveningCard,
        ),
        SettingsSwitchTile(
          icon: Icons.near_me_rounded,
          title: l.cardNextPlace,
          subtitle: l.cardNextPlaceDesc,
          value: settings.nextPlaceCard,
          onChanged: settings.setNextPlaceCard,
        ),
        SettingsSwitchTile(
          icon: Icons.flight_takeoff_rounded,
          title: l.cardTravel,
          subtitle: l.cardTravelDesc,
          value: settings.travelCard,
          onChanged: settings.setTravelCard,
        ),
        SettingsSwitchTile(
          icon: Icons.wb_sunny_outlined,
          title: l.cardWeather,
          subtitle: l.cardWeatherDesc,
          value: settings.weatherCard,
          onChanged: (v) {
            settings.setWeatherCard(v);
            if (v) controller.weather.requestPermission();
          },
        ),
        SettingsSwitchTile(
          icon: Icons.directions_run_rounded,
          title: l.spaceExercise,
          subtitle: l.exerciseSpaceDesc,
          value: settings.exerciseSpace,
          onChanged: (v) {
            settings.setExerciseSpace(v);
            if (v) {
              controller.bridge.requestActivityRecognition();
            } else {
              controller.exercise.reset();
            }
          },
        ),
        SettingsSwitchTile(
          icon: Icons.directions_car_rounded,
          title: l.cardCar,
          subtitle: l.cardCarDesc,
          value: settings.carCard,
          onChanged: settings.setCarCard,
        ),
        SettingsSwitchTile(
          icon: Icons.local_parking_rounded,
          title: l.cardParking,
          subtitle: l.cardParkingDesc,
          value: settings.parkingCard,
          onChanged: (v) {
            settings.setParkingCard(v);
            if (v) controller.cards.requestNextParkingPermission();
          },
        ),
        if (settings.carCard)
          SettingsTile(
            icon: Icons.bluetooth_rounded,
            title: l.carBluetooth,
            subtitle: l.carBluetoothDesc,
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: controller.bridge.requestBluetooth,
          ),
        SettingsChoiceTile<ScreenTimePlace>(
          icon: Icons.hourglass_bottom_rounded,
          title: l.screenTime,
          subtitle: l.screenTimeDesc,
          options: [
            (ScreenTimePlace.off, l.screenTimeOff, null),
            (ScreenTimePlace.home, l.screenTimeHome, null),
            (ScreenTimePlace.space, l.screenTimeSpace, null),
          ],
          selected: settings.screenTime,
          onChanged: (v) {
            settings.setScreenTime(v);
            if (v != ScreenTimePlace.off) {
              controller.bridge.hasUsageAccess().then((ok) {
                if (!ok) controller.bridge.openUsageAccess();
              });
            }
          },
        ),
        SettingsTile(
          icon: Icons.widgets_outlined,
          title: l.cardWidgets,
          subtitle: l.widgetCount(settings.widgets.length),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => open(const WidgetsPage()),
        ),
      ],
    ),
    SettingsSection(
      icon: Icons.swipe_vertical_rounded,
      title: l.sectionSearchGestures,
      children: [
        SettingsChoiceTile<GestureAction>(
          icon: Icons.swipe_down_rounded,
          title: l.swipeDownAction,
          subtitle: l.gesturesDesc,
          options: [
            (GestureAction.search, l.gestureSearch, null),
            (GestureAction.contacts, l.gestureContacts, null),
            (GestureAction.none, l.gestureNone, null),
          ],
          selected: settings.swipeDown,
          onChanged: settings.setSwipeDown,
        ),
        SettingsChoiceTile<GestureAction>(
          icon: Icons.swipe_up_rounded,
          title: l.swipeUpAction,
          options: [
            (GestureAction.search, l.gestureSearch, null),
            (GestureAction.contacts, l.gestureContacts, null),
            (GestureAction.none, l.gestureNone, null),
          ],
          selected: settings.swipeUp,
          onChanged: settings.setSwipeUp,
        ),
        SettingsChoiceTile<int>(
          icon: Icons.manage_search_rounded,
          title: l.searchTopApps,
          subtitle: l.searchTopAppsDesc,
          options: const [(4, '4', null), (8, '8', null)],
          selected: settings.searchTopApps,
          onChanged: settings.setSearchTopApps,
        ),
        SettingsSwitchTile(
          icon: Icons.bolt_rounded,
          title: l.autoLaunch,
          subtitle: l.autoLaunchDesc,
          value: settings.autoLaunchSingle,
          onChanged: settings.setAutoLaunchSingle,
        ),
      ],
    ),
    SettingsSection(
      icon: Icons.apps_rounded,
      title: l.sectionApps,
      children: [
        SettingsChoiceTile<AllAppsLayout>(
          icon: Icons.sort_by_alpha_rounded,
          title: l.allAppsLayout,
          options: [
            (AllAppsLayout.grid, l.layoutGrid, Icons.grid_view_rounded),
            (AllAppsLayout.list, l.layoutList, Icons.view_list_rounded),
          ],
          selected: settings.allAppsLayout,
          onChanged: settings.setAllAppsLayout,
        ),
        SettingsSwitchTile(
          icon: Icons.android_rounded,
          title: l.showSystemApps,
          subtitle: l.showSystemAppsDesc,
          value: settings.showSystemApps,
          onChanged: settings.setShowSystemApps,
        ),
        SettingsSwitchTile(
          icon: Icons.lock_clock_rounded,
          title: l.fixedOrder,
          subtitle: l.fixedOrderDesc,
          value: settings.fixedCollectionOrder,
          onChanged: settings.setFixedCollectionOrder,
        ),
        SettingsSwitchTile(
          icon: Icons.label_outline_rounded,
          title: l.collectionLabels,
          subtitle: l.collectionLabelsDesc,
          value: settings.collectionLabels,
          onChanged: settings.setCollectionLabels,
        ),
        SettingsTile(
          icon: Icons.visibility_off_rounded,
          title: l.hiddenApps,
          subtitle: l.hiddenSummary(
            settings.hiddenApps.length,
            settings.hiddenCategories.length,
          ),
          trailing: chevron,
          onTap: () => open(const HiddenPage()),
        ),
      ],
    ),
    SettingsSection(
      icon: Icons.translate_rounded,
      title: l.sectionLanguage,
      children: [
        // Each language in its own name; the check mark shows the selected one.
        for (final (code, label) in [
          ('', l.languageSystemShort),
          for (final e in languageNames.entries) (e.key, e.value),
        ])
          SettingsTile(
            icon: code.isEmpty
                ? Icons.phone_android_rounded
                : Icons.language_rounded,
            title: label,
            trailing: (settings.locale?.languageCode ?? '') == code
                ? Icon(
                    Icons.check_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            onTap: () => settings.setLocale(code.isEmpty ? null : Locale(code)),
          ),
      ],
    ),
    SettingsSection(
      icon: Icons.home_outlined,
      title: l.sectionLauncher,
      children: [
        const _DefaultHomeTile(),
        SettingsTile(
          icon: Icons.settings_rounded,
          title: l.androidSettings,
          trailing: chevron,
          onTap: controller.bridge.openSystemSettings,
        ),
      ],
    ),
    SettingsSection(
      icon: Icons.shield_outlined,
      title: l.sectionData,
      children: [
        SettingsTile(
          icon: Icons.shield_rounded,
          title: l.launchesCount(controller.predictor.totalLaunches),
          subtitle: l.privacyNote,
        ),
        SettingsSwitchTile(
          icon: Icons.history_rounded,
          title: l.learnFromUsage,
          subtitle: l.learnFromUsageDesc,
          value: settings.learnFromUsage,
          onChanged: settings.setLearnFromUsage,
        ),
        if (settings.learnFromUsage && controller.usageAccess == false)
          SettingsTile(
            icon: Icons.lock_open_rounded,
            title: l.usageAccessNeeded,
            subtitle: l.usageAccessNeededDesc,
            trailing: const Icon(Icons.open_in_new_rounded),
            onTap: controller.bridge.openUsageAccess,
          ),
        SettingsTile(
          icon: Icons.insights_rounded,
          title: l.diagnostics,
          subtitle: l.diagnosticsDesc,
          trailing: chevron,
          onTap: () => open(const DiagnosticsPage()),
        ),
        SettingsTile(
          icon: Icons.delete_sweep_rounded,
          title: l.clearHistory,
          danger: true,
          onTap: () => _confirmClear(context),
        ),
      ],
    ),
  ];
}

Future<void> _confirmClear(BuildContext context) async {
  final l = context.l10n;
  final controller = AppScope.of(context).controller;
  final messenger = ScaffoldMessenger.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.delete_sweep_rounded),
      content: Text(l.clearHistoryConfirm),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(l.delete),
        ),
      ],
    ),
  );
  if (ok == true) {
    await controller.clearHistory();
    messenger.showSnackBar(SnackBar(content: Text(l.historyCleared)));
  }
}

class _DefaultHomeTile extends StatefulWidget {
  const _DefaultHomeTile();

  @override
  State<_DefaultHomeTile> createState() => _DefaultHomeTileState();
}

class _DefaultHomeTileState extends State<_DefaultHomeTile> {
  bool? _isDefault;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppScope.of(context).controller.bridge
        .isDefaultHome()
        .then((v) {
          if (mounted) setState(() => _isDefault = v);
        })
        .catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final bridge = AppScope.of(context).controller.bridge;
    if (_isDefault == true) {
      return SettingsTile(icon: Icons.check_circle_rounded, title: l.isDefault);
    }
    return SettingsTile(
      icon: Icons.home_rounded,
      title: l.setDefault,
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: bridge.requestDefaultHome,
    );
  }
}

/// Wallpaper section: Unsplash key, daily wallpaper (Home), contextual
/// wallpaper (Space) and the photo style shared by both.
class _WallpaperSection extends StatelessWidget {
  const _WallpaperSection();

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final settings = scope.settings;
    final wallpaper = scope.wallpaper;
    final l = context.l10n;
    return ListenableBuilder(
      // Settings too: the key entry updates as soon as the dialog verifies
      // and saves the key.
      listenable: Listenable.merge([settings, wallpaper]),
      builder: (context, _) {
        final key = settings.unsplashKey;
        final hasKey = key != null && key.isNotEmpty;
        final invalid =
            wallpaper.daily.status == WallpaperStatus.invalidKey ||
            wallpaper.contextual.status == WallpaperStatus.invalidKey;
        final scheme = Theme.of(context).colorScheme;
        // Only problems replace the description; loading is a spinner next
        // to the switch, so the page doesn't jump while photos arrive.
        String? errorOf(WallpaperSlot slot) => switch (slot.status) {
          WallpaperStatus.invalidKey => l.keyInvalid,
          WallpaperStatus.error => l.wallpaperError,
          _ => null,
        };
        return SettingsSection(
          icon: Icons.wallpaper_rounded,
          title: l.sectionWallpaper,
          children: [
            SettingsTile(
              icon: Icons.key_rounded,
              title: l.unsplashKey,
              subtitle: !hasKey
                  ? l.unsplashKeyNone
                  : invalid
                  ? l.keyInvalid
                  : l.unsplashKeyVerified('…${key.substring(key.length - 4)}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasKey)
                    Icon(
                      invalid
                          ? Icons.error_outline_rounded
                          : Icons.verified_rounded,
                      color: invalid ? scheme.error : scheme.primary,
                    ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              onTap: () => showDialog<void>(
                context: context,
                builder: (_) => const _UnsplashKeyDialog(),
              ),
            ),
            // --- Daily wallpaper (Home) ---
            if (hasKey)
              SettingsSwitchTile(
                icon: Icons.today_rounded,
                title: l.dailyWallpaper,
                subtitle: errorOf(wallpaper.daily) ?? l.dailyWallpaperDesc,
                value: settings.dailyWallpaper,
                onChanged: settings.setDailyWallpaper,
                busy: wallpaper.daily.status == WallpaperStatus.loading,
              )
            else
              SettingsTile(
                icon: Icons.today_rounded,
                title: l.dailyWallpaper,
                subtitle: l.dailyWallpaperDesc,
              ),
            if (wallpaper.dailyActive)
              SettingsTile(
                icon: Icons.shuffle_rounded,
                title: l.changeDailyPhoto,
                onTap: wallpaper.nextDaily,
              ),
            // --- Contextual wallpaper (Space) ---
            if (hasKey)
              SettingsSwitchTile(
                icon: Icons.auto_awesome_rounded,
                title: l.contextWallpaper,
                subtitle:
                    errorOf(wallpaper.contextual) ?? l.contextWallpaperDesc,
                value: settings.contextWallpaper,
                onChanged: settings.setContextWallpaper,
                busy: wallpaper.contextual.status == WallpaperStatus.loading,
              )
            else
              SettingsTile(
                icon: Icons.auto_awesome_rounded,
                title: l.contextWallpaper,
                subtitle: l.contextWallpaperDesc,
              ),
            if (wallpaper.contextActive)
              SettingsTile(
                icon: Icons.shuffle_rounded,
                title: l.changePhoto,
                subtitle: wallpaper.moment == null
                    ? null
                    : l.changePhotoDesc(wallpaper.moment!.query),
                onTap: wallpaper.next,
              ),
            // --- For both photos: blur in the Space, style ---
            // Always visible: they are preferences, kept for when a photo
            // is on.
            SettingsSwitchTile(
              icon: Icons.blur_on_rounded,
              title: l.spaceHeaderBlur,
              subtitle: l.spaceHeaderBlurDesc,
              value: settings.spaceHeaderBlur,
              onChanged: settings.setSpaceHeaderBlur,
            ),
            // --- Unsplash credits ---
            SettingsSwitchTile(
              icon: Icons.copyright_rounded,
              title: l.creditHome,
              subtitle: l.creditDesc,
              value: settings.creditHome,
              onChanged: settings.setCreditHome,
            ),
            SettingsSwitchTile(
              icon: Icons.copyright_rounded,
              title: l.creditSpace,
              value: settings.creditSpace,
              onChanged: settings.setCreditSpace,
            ),
            // Hidden on screen: the credit stays here, with its link.
            for (final (view, shown, label) in [
              (WallpaperView.home, settings.creditHome, l.currentPhotoHome),
              (WallpaperView.space, settings.creditSpace, l.currentPhotoSpace),
            ])
              if (!shown)
                if (wallpaper.photoFor(view) case final photo?)
                  SettingsTile(
                    icon: Icons.photo_outlined,
                    title: label,
                    subtitle: l.photoBy(photo.authorName),
                    trailing: const Icon(Icons.open_in_new_rounded),
                    onTap: () =>
                        scope.controller.bridge.openUrl(photo.photoUrl),
                  ),
            SettingsSelectTile<WallpaperStyle>(
              icon: Icons.style_outlined,
              title: l.wallpaperStyle,
              options: [
                for (final style in WallpaperStyle.values)
                  (style, wallpaperStyleLabel(l, style)),
              ],
              selected: settings.wallpaperStyle,
              onChanged: settings.setWallpaperStyle,
            ),
          ],
        );
      },
    );
  }
}

class _UnsplashKeyDialog extends StatefulWidget {
  const _UnsplashKeyDialog();

  @override
  State<_UnsplashKeyDialog> createState() => _UnsplashKeyDialogState();
}

class _UnsplashKeyDialogState extends State<_UnsplashKeyDialog> {
  late final TextEditingController _text = TextEditingController(
    text: AppScope.of(context).settings.unsplashKey ?? '',
  );
  bool _checking = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final settings = AppScope.of(context).settings;
    final l = context.l10n;
    final key = _text.text.trim();
    if (key.isEmpty) {
      settings.setUnsplashKey(null);
      Navigator.pop(context);
      return;
    }
    setState(() {
      _checking = true;
      _error = null;
    });
    final client = UnsplashClient(key);
    try {
      final ok = await client.validate();
      if (!mounted) return;
      if (!ok) {
        setState(() {
          _checking = false;
          _error = l.keyInvalid;
        });
        return;
      }
      settings.setUnsplashKey(key);
      settings.setDailyWallpaper(true);
      settings.setContextWallpaper(true);
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _checking = false;
        _error = l.keyCheckFailed;
      });
    } finally {
      client.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scope = AppScope.of(context);
    final hasKey = scope.settings.unsplashKey != null;
    return AlertDialog(
      icon: const Icon(Icons.key_rounded),
      title: Text(l.unsplashKey),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.unsplashKeyHelp),
          const SizedBox(height: 12),
          TextField(
            controller: _text,
            enabled: !_checking,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: 'Access Key',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.wallpaperNetworkNote,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          TextButton.icon(
            onPressed: () => scope.controller.bridge.openUrl(
              'https://unsplash.com/developers',
            ),
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            label: Text(l.unsplashGetKey),
          ),
        ],
      ),
      actions: [
        if (hasKey)
          TextButton(
            onPressed: _checking
                ? null
                : () {
                    scope.settings.setUnsplashKey(null);
                    Navigator.pop(context);
                  },
            child: Text(l.remove),
          ),
        TextButton(
          onPressed: _checking ? null : () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: _checking ? null : _save,
          child: _checking
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l.save),
        ),
      ],
    );
  }
}

/// Places section: home and work detection, and corrections.
class _PlacesSection extends StatelessWidget {
  const _PlacesSection();

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final settings = scope.settings;
    final places = scope.controller.places;
    final l = context.l10n;
    return ListenableBuilder(
      listenable: places,
      builder: (context, _) {
        String status(Place? p, String learning) {
          if (p == null) return learning;
          if (p.userRole != null) return l.placeByUser;
          return l.placeRecognized((p.roleConfidence * 100).round());
        }

        final current = places.current;
        final role = current?.effectiveRole;
        return SettingsSection(
          icon: Icons.home_work_outlined,
          title: l.sectionPlaces,
          children: [
            SettingsSwitchTile(
              icon: Icons.my_location_rounded,
              title: l.placesEnabled,
              subtitle: l.placesEnabledDesc,
              value: settings.placesEnabled,
              onChanged: (v) {
                settings.setPlacesEnabled(v);
                if (v) places.requestPermission();
              },
            ),
            if (settings.placesEnabled) ...[
              if (places.permission == false)
                SettingsTile(
                  icon: Icons.location_on_rounded,
                  title: l.allow,
                  subtitle: l.placesPermission,
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: places.requestPermission,
                ),
              SettingsTile(
                icon: Icons.home_rounded,
                title: l.placeHome,
                subtitle: status(places.home, l.placeLearningHome),
              ),
              SettingsTile(
                icon: Icons.work_rounded,
                title: l.placeWork,
                subtitle: status(places.work, l.placeLearningWork),
              ),
              SettingsChoiceTile<String>(
                icon: Icons.badge_outlined,
                title: l.workLabel,
                subtitle: settings.workLabel != 'auto'
                    ? null
                    : switch (places.workKind) {
                        WorkKind.work => l.workKindDetected(l.workLabelWork),
                        WorkKind.school => l.workKindDetected(
                          l.workLabelSchool,
                        ),
                        null => l.workKindLearning,
                      },
                options: [
                  ('auto', l.workLabelAutomatic, null),
                  ('lavoro', l.workLabelWork, null),
                  ('scuola', l.workLabelSchool, null),
                ],
                selected: settings.workLabel,
                onChanged: settings.setWorkLabel,
              ),
              if (current == null)
                SettingsTile(
                  icon: Icons.near_me_disabled_outlined,
                  title: l.hereUnknown,
                )
              else ...[
                if (role != PlaceRole.home)
                  SettingsTile(
                    icon: Icons.home_outlined,
                    title: l.hereIsHome,
                    onTap: () => places.setCurrentAs(PlaceRole.home),
                  )
                else
                  SettingsTile(
                    icon: Icons.home_outlined,
                    title: l.notHome,
                    onTap: () => places.notThis(PlaceRole.home),
                  ),
                if (role != PlaceRole.work)
                  SettingsTile(
                    icon: Icons.work_outline_rounded,
                    title: l.hereIsWork,
                    onTap: () => places.setCurrentAs(PlaceRole.work),
                  )
                else
                  SettingsTile(
                    icon: Icons.work_outline_rounded,
                    title: l.notWork,
                    onTap: () => places.notThis(PlaceRole.work),
                  ),
              ],
              SettingsTile(
                icon: Icons.restart_alt_rounded,
                title: l.resetPlaces,
                subtitle: l.placesCount(places.engine.places.length),
                danger: true,
                onTap: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (d) => AlertDialog(
                      icon: const Icon(Icons.restart_alt_rounded),
                      content: Text(l.resetPlacesConfirm),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(d, false),
                          child: Text(l.cancel),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(d, true),
                          child: Text(l.delete),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) await places.reset();
                },
              ),
            ],
          ],
        );
      },
    );
  }
}
