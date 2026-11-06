/// Categorie delle app e regole per assegnarle.
///
/// Ordine di priorità (spec-motore-contesto §7.3):
/// utente > dizionario > manifest > euristica > sistema/altro.
library;

enum AppCategory {
  social,
  messaging,
  music,
  video,
  photo,
  news,
  maps,
  productivity,
  work,
  education,
  finance,
  shopping,
  food,
  health,
  games,
  tools,
  system,
  other;

  static AppCategory? tryParse(String? name) {
    if (name == null) return null;
    for (final c in values) {
      if (c.name == name) return c;
    }
    return null;
  }
}

/// Ordine predefinito delle card nelle Collections, usato quando i dati
/// sono insufficienti o l'utente sceglie l'ordine fisso.
const List<AppCategory> defaultCategoryOrder = [
  AppCategory.messaging,
  AppCategory.social,
  AppCategory.music,
  AppCategory.video,
  AppCategory.photo,
  AppCategory.news,
  AppCategory.maps,
  AppCategory.productivity,
  AppCategory.work,
  AppCategory.education,
  AppCategory.finance,
  AppCategory.shopping,
  AppCategory.food,
  AppCategory.health,
  AppCategory.games,
  AppCategory.tools,
  AppCategory.system,
  AppCategory.other,
];

/// Da dove arriva la categoria assegnata.
enum CategorySource { user, dictionary, manifest, heuristic, fallback }

class CategoryAssignment {
  const CategoryAssignment(this.category, this.source);
  final AppCategory category;
  final CategorySource source;
}

/// Valori di `ApplicationInfo.category` di Android.
AppCategory? categoryFromManifest(int? value) {
  switch (value) {
    case 0:
      return AppCategory.games;
    case 1:
      return AppCategory.music;
    case 2:
      return AppCategory.video;
    case 3:
      return AppCategory.photo;
    case 4:
      return AppCategory.social;
    case 5:
      return AppCategory.news;
    case 6:
      return AppCategory.maps;
    case 7:
      return AppCategory.productivity;
    case 8:
      return AppCategory.tools; // accessibilità
    default:
      return null;
  }
}

/// Assegna la categoria a un'app.
CategoryAssignment categorize({
  required String packageName,
  required String label,
  required bool isSystem,
  int? manifestCategory,
  AppCategory? userOverride,
}) {
  if (userOverride != null) {
    return CategoryAssignment(userOverride, CategorySource.user);
  }
  final dict = categoryDictionary[packageName];
  if (dict != null) return CategoryAssignment(dict, CategorySource.dictionary);

  final manifest = categoryFromManifest(manifestCategory);
  if (manifest != null) {
    return CategoryAssignment(manifest, CategorySource.manifest);
  }

  final heuristic = _heuristic(packageName, label);
  if (heuristic != null) {
    return CategoryAssignment(heuristic, CategorySource.heuristic);
  }

  return CategoryAssignment(
    isSystem ? AppCategory.system : AppCategory.other,
    CategorySource.fallback,
  );
}

AppCategory? _heuristic(String packageName, String label) {
  final haystack = '${packageName.toLowerCase()} ${label.toLowerCase()}';
  for (final rule in _keywordRules) {
    for (final k in rule.keywords) {
      if (haystack.contains(k)) return rule.category;
    }
  }
  return null;
}

class _KeywordRule {
  const _KeywordRule(this.category, this.keywords);
  final AppCategory category;
  final List<String> keywords;
}

// Ordine importante: le regole più specifiche prima.
const List<_KeywordRule> _keywordRules = [
  _KeywordRule(AppCategory.messaging, [
    'messag',
    'messenger',
    'chat',
    'sms',
    'mms',
    'dialer',
    'telefono',
  ]),
  _KeywordRule(AppCategory.finance, [
    'bank',
    'banca',
    'banking',
    'wallet',
    'pay',
    'finance',
    'crypto',
    'trading',
    'invest',
    'borsa',
  ]),
  _KeywordRule(AppCategory.music, [
    'music',
    'musica',
    'radio',
    'podcast',
    'audio',
    'fm.',
  ]),
  _KeywordRule(AppCategory.video, ['video', 'tv', 'stream', 'film', 'movie']),
  _KeywordRule(AppCategory.photo, [
    'photo',
    'foto',
    'camera',
    'gallery',
    'galleria',
    'image',
    'snap',
  ]),
  _KeywordRule(AppCategory.maps, [
    'maps',
    'mappe',
    'navig',
    'gps',
    'transit',
    'trasporti',
    'train',
    'treni',
    'taxi',
    'travel',
    'viaggi',
    'flight',
    'voli',
    'booking',
    'hotel',
    'parking',
    'parcheggio',
  ]),
  _KeywordRule(AppCategory.food, [
    'food',
    'cibo',
    'recipe',
    'ricett',
    'restaurant',
    'ristorant',
    'delivery',
    'pizza',
  ]),
  _KeywordRule(AppCategory.shopping, [
    'shop',
    'market',
    'negozio',
    'coupon',
    'offert',
  ]),
  _KeywordRule(AppCategory.health, [
    'health',
    'salute',
    'fit',
    'workout',
    'sport',
    'sleep',
    'medit',
    'yoga',
    'step',
    'diet',
  ]),
  _KeywordRule(AppCategory.news, [
    'news',
    'notizie',
    'giornale',
    'journal',
    'rss',
    'feed',
    'magazine',
  ]),
  _KeywordRule(AppCategory.education, [
    'learn',
    'school',
    'scuola',
    'class',
    'universit',
    'study',
    'studio',
    'dictionary',
    'dizionario',
    'language',
    'lingu',
  ]),
  _KeywordRule(AppCategory.work, [
    'office',
    'teams',
    'slack',
    'meet',
    'zoom',
    'webex',
    'jira',
    'crm',
    'erp',
    'work',
    'lavoro',
    'vpn',
    'authenticator',
  ]),
  _KeywordRule(AppCategory.productivity, [
    'note',
    'calendar',
    'calendario',
    'todo',
    'task',
    'docs',
    'document',
    'pdf',
    'drive',
    'cloud',
    'mail',
    'email',
    'keep',
    'scanner',
  ]),
  _KeywordRule(AppCategory.games, ['game', 'gioc', 'puzzle', 'chess', 'play.']),
  _KeywordRule(AppCategory.tools, [
    'calculator',
    'calcolat',
    'clock',
    'orologio',
    'file',
    'settings',
    'impostazioni',
    'weather',
    'meteo',
    'torch',
    'flashlight',
    'launcher',
    'keyboard',
    'tastiera',
    'backup',
    'cleaner',
    'browser',
  ]),
];

/// Dizionario offline pacchetto → categoria (prima versione, da ampliare).
const Map<String, AppCategory> categoryDictionary = {
  // Messaggi
  'com.whatsapp': AppCategory.messaging,
  'com.whatsapp.w4b': AppCategory.messaging,
  'org.telegram.messenger': AppCategory.messaging,
  'org.thunderdog.challegram': AppCategory.messaging, // Telegram X
  'org.telegram.plus': AppCategory.messaging,
  'org.thoughtcrime.securesms': AppCategory.messaging,
  'com.facebook.orca': AppCategory.messaging,
  'com.google.android.apps.messaging': AppCategory.messaging,
  'com.samsung.android.messaging': AppCategory.messaging,
  'com.google.android.dialer': AppCategory.messaging,
  'com.samsung.android.dialer': AppCategory.messaging,
  'com.android.dialer': AppCategory.messaging,
  'com.google.android.contacts': AppCategory.messaging,
  'com.samsung.android.app.contacts': AppCategory.messaging,
  'com.viber.voip': AppCategory.messaging,
  'com.discord': AppCategory.messaging,
  'im.vector.app': AppCategory.messaging,
  'eu.siacs.conversations': AppCategory.messaging,
  'com.skype.raider': AppCategory.messaging,
  // Social
  'com.instagram.android': AppCategory.social,
  'com.facebook.katana': AppCategory.social,
  'com.twitter.android': AppCategory.social,
  'com.zhiliaoapp.musically': AppCategory.social,
  'com.snapchat.android': AppCategory.social,
  'com.linkedin.android': AppCategory.social,
  'com.reddit.frontpage': AppCategory.social,
  'com.pinterest': AppCategory.social,
  'org.joinmastodon.android': AppCategory.social,
  'com.instagram.barcelona': AppCategory.social,
  'xyz.blueskyweb.app': AppCategory.social,
  'com.bereal.ft': AppCategory.social,
  // Musica e audio
  'com.spotify.music': AppCategory.music,
  'com.google.android.apps.youtube.music': AppCategory.music,
  'com.amazon.mp3': AppCategory.music,
  'deezer.android.app': AppCategory.music,
  'com.apple.android.music': AppCategory.music,
  'com.shazam.android': AppCategory.music,
  'com.audible.application': AppCategory.music,
  'com.google.android.apps.podcasts': AppCategory.music,
  'au.com.shiftyjelly.pocketcasts': AppCategory.music,
  'com.soundcloud.android': AppCategory.music,
  // Video
  'com.google.android.youtube': AppCategory.video,
  'com.netflix.mediaclient': AppCategory.video,
  'com.amazon.avod.thirdpartyclient': AppCategory.video,
  'com.disney.disneyplus': AppCategory.video,
  'tv.twitch.android.app': AppCategory.video,
  'it.rainet.raiplay': AppCategory.video,
  'it.mediaset.infinity': AppCategory.video,
  'com.dazn': AppCategory.video,
  'com.nowtv.it': AppCategory.video,
  'org.videolan.vlc': AppCategory.video,
  // Foto
  'com.google.android.apps.photos': AppCategory.photo,
  'com.google.android.GoogleCamera': AppCategory.photo,
  'com.sec.android.app.camera': AppCategory.photo,
  'com.sec.android.gallery3d': AppCategory.photo,
  'com.android.camera': AppCategory.photo,
  'com.android.camera2': AppCategory.photo,
  'com.adobe.lrmobile': AppCategory.photo,
  'com.niksoftware.snapseed': AppCategory.photo,
  'com.vsco.cam': AppCategory.photo,
  // News
  'com.google.android.apps.magazines': AppCategory.news,
  'it.repubblica.repubblica': AppCategory.news,
  'it.corriere.app': AppCategory.news,
  'it.ilpost.app': AppCategory.news,
  'com.ansa.app': AppCategory.news,
  'bbc.mobile.news.ww': AppCategory.news,
  'com.nytimes.android': AppCategory.news,
  'com.devhd.feedly': AppCategory.news,
  // Mappe e viaggio
  'com.google.android.apps.maps': AppCategory.maps,
  'com.waze': AppCategory.maps,
  'net.osmand': AppCategory.maps,
  'net.osmand.plus': AppCategory.maps,
  'app.organicmaps': AppCategory.maps,
  'com.citymapper.app.release': AppCategory.maps,
  'com.moovit.app': AppCategory.maps,
  'com.ubercab': AppCategory.maps,
  'com.trenitalia.trenitalia': AppCategory.maps,
  'net.pluservice.busitaliaveneto': AppCategory.maps,
  'com.busitalia.android': AppCategory.maps,
  'it.italotreno': AppCategory.maps,
  'com.ryanair.cheapflights': AppCategory.maps,
  'com.booking': AppCategory.maps,
  'com.airbnb.android': AppCategory.maps,
  'com.tripadvisor.tripadvisor': AppCategory.maps,
  'com.google.android.apps.travel.onthego': AppCategory.maps,
  // Produttività
  'com.google.android.gm': AppCategory.productivity,
  'com.google.android.calendar': AppCategory.productivity,
  'com.samsung.android.calendar': AppCategory.productivity,
  'com.google.android.keep': AppCategory.productivity,
  'com.google.android.apps.docs': AppCategory.productivity,
  'com.google.android.apps.docs.editors.docs': AppCategory.productivity,
  'com.google.android.apps.docs.editors.sheets': AppCategory.productivity,
  'com.google.android.apps.docs.editors.slides': AppCategory.productivity,
  'com.google.android.apps.tasks': AppCategory.productivity,
  'com.notion.id': AppCategory.productivity,
  'md.obsidian': AppCategory.productivity,
  'com.todoist': AppCategory.productivity,
  'com.dropbox.android': AppCategory.productivity,
  'com.microsoft.office.onenote': AppCategory.productivity,
  'com.microsoft.todos': AppCategory.productivity,
  'ch.protonmail.android': AppCategory.productivity,
  'com.fsck.k9': AppCategory.productivity,
  'net.thunderbird.android': AppCategory.productivity,
  'com.adobe.reader': AppCategory.productivity,
  // Lavoro
  'com.microsoft.teams': AppCategory.work,
  'com.microsoft.office.outlook': AppCategory.work,
  'com.microsoft.office.word': AppCategory.work,
  'com.microsoft.office.excel': AppCategory.work,
  'com.microsoft.office.powerpoint': AppCategory.work,
  'com.microsoft.office.officehubrow': AppCategory.work,
  'com.Slack': AppCategory.work,
  'us.zoom.videomeetings': AppCategory.work,
  'com.google.android.apps.meetings': AppCategory.work,
  'com.cisco.webex.meetings': AppCategory.work,
  'com.atlassian.android.jira.core': AppCategory.work,
  'com.microsoft.skydrive': AppCategory.work,
  'com.azure.authenticator': AppCategory.work,
  'com.google.android.apps.authenticator2': AppCategory.work,
  // Studio
  'com.google.android.apps.classroom': AppCategory.education,
  'com.duolingo': AppCategory.education,
  'org.wikipedia': AppCategory.education,
  'com.google.android.apps.translate': AppCategory.education,
  'com.deepl.mobiletranslator': AppCategory.education,
  'org.ankidroid.android': AppCategory.education,
  'com.quizlet.quizletandroid': AppCategory.education,
  'com.google.android.apps.books': AppCategory.education,
  'com.amazon.kindle': AppCategory.education,
  // Finanza
  'com.paypal.android.p2pmobile': AppCategory.finance,
  'com.revolut.revolut': AppCategory.finance,
  'de.number26.android': AppCategory.finance,
  'com.satispay.customer': AppCategory.finance,
  'com.google.android.apps.walletnfcrel': AppCategory.finance,
  'com.samsung.android.spay': AppCategory.finance,
  'com.latuabancaperandroid': AppCategory.finance,
  'it.bnl.apps.banking': AppCategory.finance,
  'com.unicredit': AppCategory.finance,
  'posteitaliane.posteapp.appbpol': AppCategory.finance,
  'it.poste.postepay': AppCategory.finance,
  'com.fineco.it': AppCategory.finance,
  'com.wise.android': AppCategory.finance,
  'com.binance.dev': AppCategory.finance,
  // Shopping
  'com.amazon.mShop.android.shopping': AppCategory.shopping,
  'com.ebay.mobile': AppCategory.shopping,
  'com.zalando.mobile': AppCategory.shopping,
  'com.einnovation.temu': AppCategory.shopping,
  'com.alibaba.aliexpresshd': AppCategory.shopping,
  'com.vinted': AppCategory.shopping,
  'it.subito': AppCategory.shopping,
  'com.ikea.kompis': AppCategory.shopping,
  'com.android.vending': AppCategory.shopping,
  // Cibo
  'com.deliveroo.orderapp': AppCategory.food,
  'com.glovoapp.consumer': AppCategory.food,
  'com.justeat.app.it': AppCategory.food,
  'com.ubercab.eats': AppCategory.food,
  'com.thefork.app': AppCategory.food,
  'com.app.tgtg': AppCategory.food,
  'it.giallozafferano.app': AppCategory.food,
  // Salute e sport
  'com.google.android.apps.fitness': AppCategory.health,
  'com.strava': AppCategory.health,
  'com.sec.android.app.shealth': AppCategory.health,
  'com.garmin.android.apps.connectmobile': AppCategory.health,
  'com.fitbit.FitbitMobile': AppCategory.health,
  'com.myfitnesspal.android': AppCategory.health,
  'com.calm.android': AppCategory.health,
  'com.getsomeheadspace.android': AppCategory.health,
  'com.google.android.apps.healthdata': AppCategory.health,
  'it.ministerodellasalute.immuni': AppCategory.health,
  // Strumenti
  'com.android.chrome': AppCategory.tools,
  'org.mozilla.firefox': AppCategory.tools,
  'org.mozilla.fenix': AppCategory.tools,
  'com.brave.browser': AppCategory.tools,
  'com.duckduckgo.mobile.android': AppCategory.tools,
  'com.microsoft.emmx': AppCategory.tools,
  'com.sec.android.app.sbrowser': AppCategory.tools,
  'com.google.android.calculator': AppCategory.tools,
  'com.google.android.deskclock': AppCategory.tools,
  'com.sec.android.app.clockpackage': AppCategory.tools,
  'com.google.android.apps.nbu.files': AppCategory.tools,
  'com.google.android.documentsui': AppCategory.tools,
  'com.sec.android.app.myfiles': AppCategory.tools,
  'com.google.android.googlequicksearchbox': AppCategory.tools,
  'com.google.android.apps.weather': AppCategory.tools,
  'com.google.android.apps.recorder': AppCategory.tools,
  'com.bitwarden': AppCategory.tools,
  'com.x8bit.bitwarden': AppCategory.tools,
  'com.agilebits.onepassword': AppCategory.tools,
  'org.fdroid.fdroid': AppCategory.tools,
  'it.pagopa.io.app': AppCategory.tools, // IO, servizi pubblici
  'it.ipzs.cieid': AppCategory.tools,
  // Sistema
  'com.android.settings': AppCategory.system,
  'com.google.android.apps.wellbeing': AppCategory.system,
  'com.samsung.android.app.updatecenter': AppCategory.system,
  'com.google.android.apps.safetyhub': AppCategory.system,
  'com.samsung.android.lool': AppCategory.system,
};
