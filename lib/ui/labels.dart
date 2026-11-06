/// Etichette tradotte e icone per categorie, fasce orarie e stili.
library;

import 'package:flutter/material.dart';

import '../core/categories.dart';
import '../core/space.dart';
import '../core/time_context.dart';
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

String spaceLabel(L10n l, SpaceKind k, {String workLabel = 'auto'}) =>
    switch (k) {
      SpaceKind.home => l.spaceHome,
      SpaceKind.work => switch (workLabel) {
        'lavoro' => l.spaceWork,
        'scuola' => l.spaceSchool,
        _ => l.spaceWorkOrSchool,
      },
      SpaceKind.moving => l.spaceMoving,
      SpaceKind.listening => l.spaceListening,
      SpaceKind.travel => l.spaceTravel,
      _ => slotLabel(l, k.slot!),
    };

IconData spaceIcon(SpaceKind k) => switch (k) {
  SpaceKind.home => Icons.home_rounded,
  SpaceKind.work => Icons.work_rounded,
  SpaceKind.moving => Icons.directions_car_rounded,
  SpaceKind.listening => Icons.headphones_rounded,
  SpaceKind.travel => Icons.flight_takeoff_rounded,
  _ => slotIcon(k.slot!),
};
