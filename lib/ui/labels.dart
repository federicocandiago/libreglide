/// Localized labels and icons for categories, time slots and styles.
library;

import 'package:flutter/material.dart';

import '../core/categories.dart';
import '../core/places.dart';
import '../core/space.dart';
import '../core/space_profile.dart';
import '../core/time_context.dart';
import '../core/wallpaper_moment.dart';
import '../core/weather.dart';
import '../l10n/gen/app_localizations.dart';

extension L10nContext on BuildContext {
  L10n get l10n => L10n.of(this);
}

String categoryLabel(L10n l, AppCategory c) => switch (c) {
  AppCategory.social => l.catSocial,
  AppCategory.messaging => l.catMessaging,
  AppCategory.music => l.catMusic,
  AppCategory.video => l.catVideo,
  AppCategory.photo => l.catPhoto,
  AppCategory.news => l.catNews,
  AppCategory.maps => l.catMaps,
  AppCategory.productivity => l.catProductivity,
  AppCategory.work => l.catWork,
  AppCategory.education => l.catEducation,
  AppCategory.finance => l.catFinance,
  AppCategory.shopping => l.catShopping,
  AppCategory.food => l.catFood,
  AppCategory.health => l.catHealth,
  AppCategory.games => l.catGames,
  AppCategory.tools => l.catTools,
  AppCategory.system => l.catSystem,
  AppCategory.other => l.catOther,
};

IconData categoryIcon(AppCategory c) => switch (c) {
  AppCategory.social => Icons.groups_rounded,
  AppCategory.messaging => Icons.forum_rounded,
  AppCategory.music => Icons.headphones_rounded,
  AppCategory.video => Icons.smart_display_rounded,
  AppCategory.photo => Icons.photo_camera_rounded,
  AppCategory.news => Icons.newspaper_rounded,
  AppCategory.maps => Icons.explore_rounded,
  AppCategory.productivity => Icons.task_alt_rounded,
  AppCategory.work => Icons.work_rounded,
  AppCategory.education => Icons.school_rounded,
  AppCategory.finance => Icons.account_balance_wallet_rounded,
  AppCategory.shopping => Icons.shopping_bag_rounded,
  AppCategory.food => Icons.restaurant_rounded,
  AppCategory.health => Icons.favorite_rounded,
  AppCategory.games => Icons.sports_esports_rounded,
  AppCategory.tools => Icons.handyman_rounded,
  AppCategory.system => Icons.settings_rounded,
  AppCategory.other => Icons.apps_rounded,
};

String slotLabel(L10n l, Slot s) => switch (s) {
  Slot.wakeUp => l.slotWakeUp,
  Slot.morning => l.slotMorning,
  Slot.lunch => l.slotLunch,
  Slot.afternoon => l.slotAfternoon,
  Slot.evening => l.slotEvening,
  Slot.night => l.slotNight,
};

IconData slotIcon(Slot s) => switch (s) {
  Slot.wakeUp => Icons.wb_twilight_rounded,
  Slot.morning => Icons.light_mode_rounded,
  Slot.lunch => Icons.lunch_dining_rounded,
  Slot.afternoon => Icons.wb_sunny_rounded,
  Slot.evening => Icons.nights_stay_rounded,
  Slot.night => Icons.bedtime_rounded,
};

String dayTypeLabel(L10n l, DayType d) => switch (d) {
  DayType.workday => l.dayWorkday,
  DayType.holiday => l.dayHoliday,
};

String presetLabel(L10n l, String id) => switch (id) {
  'laguna' => l.presetLaguna,
  'salvia' => l.presetSalvia,
  'terracotta' => l.presetTerracotta,
  'ambra' => l.presetAmbra,
  'lampone' => l.presetLampone,
  'lavanda' => l.presetLavanda,
  'petrolio' => l.presetPetrolio,
  'grafite' => l.presetGrafite,
  _ => id,
};

String paletteStyleLabel(L10n l, DynamicSchemeVariant v) => switch (v) {
  DynamicSchemeVariant.tonalSpot => l.styleTonalSpot,
  DynamicSchemeVariant.vibrant => l.styleVibrant,
  DynamicSchemeVariant.expressive => l.styleExpressive,
  DynamicSchemeVariant.neutral => l.styleNeutral,
  DynamicSchemeVariant.monochrome => l.styleMonochrome,
  _ => v.name,
};

String spaceLabel(L10n l, SpaceKind k, {WorkKind? workKind}) => switch (k) {
  SpaceKind.home => l.spaceHome,
  SpaceKind.work => switch (workKind) {
    WorkKind.work => l.spaceWork,
    WorkKind.school => l.spaceSchool,
    null => l.spaceWorkOrSchool,
  },
  SpaceKind.moving => l.spaceMoving,
  SpaceKind.listening => l.spaceListening,
  SpaceKind.nightOut => l.spaceNightOut,
  SpaceKind.exercise => l.spaceExercise,
  SpaceKind.travel => l.spaceTravel,
  _ => slotLabel(l, k.slot!),
};

IconData spaceIcon(SpaceKind k) => switch (k) {
  SpaceKind.home => Icons.home_rounded,
  SpaceKind.work => Icons.work_rounded,
  SpaceKind.moving => Icons.directions_car_rounded,
  SpaceKind.listening => Icons.headphones_rounded,
  SpaceKind.nightOut => Icons.nightlife_rounded,
  SpaceKind.exercise => Icons.directions_run_rounded,
  SpaceKind.travel => Icons.flight_takeoff_rounded,
  _ => slotIcon(k.slot!),
};

String spaceCardLabel(L10n l, SpaceCard card) => switch (card) {
  SpaceCard.car => l.cardCar,
  SpaceCard.parking => l.cardParking,
  SpaceCard.evening => l.cardEvening,
  SpaceCard.alarm => l.nextAlarm,
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

IconData spaceCardIcon(SpaceCard card) => switch (card) {
  SpaceCard.car => Icons.directions_car_rounded,
  SpaceCard.parking => Icons.local_parking_rounded,
  SpaceCard.evening => Icons.bedtime_rounded,
  SpaceCard.alarm => Icons.alarm_rounded,
  SpaceCard.media => Icons.headphones_rounded,
  SpaceCard.travel => Icons.flight_rounded,
  SpaceCard.nextPlace => Icons.near_me_rounded,
  SpaceCard.agenda => Icons.event_rounded,
  SpaceCard.weather => Icons.wb_sunny_rounded,
  SpaceCard.apps => Icons.auto_awesome_rounded,
  SpaceCard.category => Icons.apps_rounded,
  SpaceCard.screenTime => Icons.hourglass_bottom_rounded,
  SpaceCard.placesInvite => Icons.home_work_rounded,
};

String wallpaperStyleLabel(L10n l, WallpaperStyle s) => switch (s) {
  WallpaperStyle.none => l.photoStyleNone,
  WallpaperStyle.aesthetic => l.photoStyleAesthetic,
  WallpaperStyle.nature => l.photoStyleNature,
  WallpaperStyle.minimal => l.photoStyleMinimal,
  WallpaperStyle.abstract => l.photoStyleAbstract,
  WallpaperStyle.architecture => l.photoStyleArchitecture,
  WallpaperStyle.dark => l.photoStyleDark,
};

/// Weather condition icon (night variant for clear sky).
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

/// [celsius] in the unit of the phone's region (°F in the US), rounded.
String degrees(double celsius) => formatDegrees(
  celsius,
  fahrenheit: usesFahrenheit(
    WidgetsBinding.instance.platformDispatcher.locale.countryCode,
  ),
);
