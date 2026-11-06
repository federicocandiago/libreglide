/// Riconoscimento dei luoghi: casa, lavoro/scuola e luoghi frequenti
/// (spec-motore-contesto §6), tutto in locale e senza nomi da scrivere.
///
/// - I campioni (posizione precisa e impronta del Wi-Fi) vengono raggruppati
///   in luoghi; il Wi-Fi riconosciuto vale più del GPS, soprattutto al chiuso.
/// - Casa: il luogo dove dormi (il buco più lungo tra un campione e l'altro
///   in ogni giornata, se inizia e finisce nello stesso luogo), con ricarica
///   notturna e primo/ultimo uso del giorno.
/// - Lavoro/scuola: il luogo dei giorni feriali, assente nel weekend, con
///   orari di arrivo regolari.
/// - I campioni oltre 100 km da casa (viaggi) non contano.
/// - Le correzioni dell'utente non vengono mai sovrascritte.
library;

import 'dart:math' as math;

import 'time_context.dart';

class LocationSample {
  const LocationSample({
    required this.ts,
    this.lat,
    this.lon,
    this.accuracy,
    this.wifi,
    this.charging = false,
  });

  factory LocationSample.fromMap(Map<String, Object?> m) => LocationSample(
    ts: DateTime.fromMillisecondsSinceEpoch(m['ts']! as int),
    lat: (m['lat'] as num?)?.toDouble(),
    lon: (m['lon'] as num?)?.toDouble(),
    accuracy: (m['accuracy'] as num?)?.toDouble(),
    wifi: m['wifi'] as String?,
    charging: (m['charging'] as int? ?? 0) == 1,
  );

  final DateTime ts;
  final double? lat;
  final double? lon;

  /// Precisione in metri.
  final double? accuracy;

  /// Impronta (hash) della rete Wi-Fi, mai il nome.
  final String? wifi;
  final bool charging;

  bool get hasGoodFix =>
      lat != null && lon != null && (accuracy ?? 999) <= maxGoodAccuracy;

  Map<String, Object?> toMap() => {
    'ts': ts.millisecondsSinceEpoch,
    'lat': lat,
    'lon': lon,
    'accuracy': accuracy,
    'wifi': wifi,
    'charging': charging ? 1 : 0,
  };
}

enum PlaceRole { home, work, frequent, none }

class Place {
  Place({
    required this.id,
    required this.lat,
    required this.lon,
    required this.firstSeen,
    required this.lastSeen,
    this.weight = 0,
    this.role = PlaceRole.none,
    this.roleConfidence = 0,
    this.userRole,
    Set<PlaceRole>? blocked,
    Map<String, int>? wifiHits,
  }) : blocked = blocked ?? {},
       wifiHits = wifiHits ?? {};

  factory Place.fromJson(Map<String, dynamic> j) => Place(
    id: j['id'] as int,
    lat: (j['lat'] as num).toDouble(),
    lon: (j['lon'] as num).toDouble(),
    weight: (j['weight'] as num).toDouble(),
    firstSeen: DateTime.fromMillisecondsSinceEpoch(j['firstSeen'] as int),
    lastSeen: DateTime.fromMillisecondsSinceEpoch(j['lastSeen'] as int),
    role: PlaceRole.values.byName(j['role'] as String),
    roleConfidence: (j['roleConfidence'] as num).toDouble(),
    userRole: j['userRole'] == null
        ? null
        : PlaceRole.values.byName(j['userRole'] as String),
    blocked: {
      for (final b in (j['blocked'] as List? ?? const []))
        PlaceRole.values.byName(b as String),
    },
    wifiHits: (j['wifiHits'] as Map?)?.map(
      (k, v) => MapEntry(k as String, v as int),
    ),
  );

  final int id;
  double lat;
  double lon;

  /// Somma dei pesi (1/precisione²) dei campioni: per la media del centro.
  double weight;
  DateTime firstSeen;
  DateTime lastSeen;
  PlaceRole role;
  double roleConfidence;

  /// Ruolo scelto dall'utente: vince sempre sull'inferenza.
  PlaceRole? userRole;

  /// Ruoli che l'utente ha escluso ("Questa non è casa mia").
  final Set<PlaceRole> blocked;

  /// Impronte Wi-Fi viste qui con una buona posizione, e quante volte.
  final Map<String, int> wifiHits;

  /// Il ruolo effettivo.
  PlaceRole get effectiveRole => userRole ?? role;

  bool trustsWifi(String hash) => (wifiHits[hash] ?? 0) >= trustedWifiHits;

  Map<String, dynamic> toJson() => {
    'id': id,
    'lat': lat,
    'lon': lon,
    'weight': weight,
    'firstSeen': firstSeen.millisecondsSinceEpoch,
    'lastSeen': lastSeen.millisecondsSinceEpoch,
    'role': role.name,
    'roleConfidence': roleConfidence,
    'userRole': userRole?.name,
    'blocked': [for (final b in blocked) b.name],
    'wifiHits': wifiHits,
  };
}

const double maxGoodAccuracy = 100;
const double placeRadius = 120;
const double mergeDistance = 80;
const int trustedWifiHits = 3;
const double travelDistanceKm = 100;
const Duration sleepMinGap = Duration(hours: 4);
const Duration visitMaxGap = Duration(hours: 4);
const Duration roleWindow = Duration(days: 28);
const double roleThreshold = 0.6;
const double roleHysteresis = 0.15;

/// Distanza in metri (formula dell'emisenoverso).
double distanceMeters(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371000.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLon = rad(lon2 - lon1);
  final a =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(lat1)) *
          math.cos(rad(lat2)) *
          math.pow(math.sin(dLon / 2), 2);
  return 2 * r * math.asin(math.sqrt(a.toDouble()));
}

double _sigmoid(double x) => 1 / (1 + math.exp(-x));

/// Punteggi di un luogo, per la diagnostica e i test.
class PlaceScores {
  const PlaceScores(this.homeConfidence, this.workConfidence, this.days);
  final double homeConfidence;
  final double workConfidence;
  final int days;
}

class PlaceEngine {
  PlaceEngine({List<Place>? places}) : places = places ?? [] {
    _nextId = this.places.fold(0, (m, p) => math.max(m, p.id)) + 1;
  }

  factory PlaceEngine.fromJson(List<dynamic> json) => PlaceEngine(
    places: [for (final j in json) Place.fromJson(j as Map<String, dynamic>)],
  );

  final List<Place> places;
  late int _nextId;

  /// Punteggi dell'ultima inferenza, per luogo.
  final Map<int, PlaceScores> scores = {};

  List<Map<String, dynamic>> toJson() => [for (final p in places) p.toJson()];

  Place? byId(int? id) {
    if (id == null) return null;
    for (final p in places) {
      if (p.id == id) return p;
    }
    return null;
  }

  Place? withRole(PlaceRole role) {
    for (final p in places) {
      if (p.effectiveRole == role) return p;
    }
    return null;
  }

  /// Assegna un campione a un luogo (creandolo se serve) e restituisce
  /// l'id, oppure null se la posizione non è abbastanza buona.
  int? addSample(LocationSample s) {
    // 1. Wi-Fi conosciuto: vale anche senza posizione, ma se la posizione è
    // buona e dice che sei lontano (stesso nome di rete altrove, catene,
    // eduroam) vince la posizione.
    if (s.wifi != null) {
      for (final p in places) {
        if (!p.trustsWifi(s.wifi!)) continue;
        if (s.hasGoodFix &&
            distanceMeters(p.lat, p.lon, s.lat!, s.lon!) > 400) {
          continue;
        }
        p.lastSeen = s.ts;
        return p.id;
      }
    }
    if (!s.hasGoodFix) return null;

    // 2. Luogo più vicino entro il raggio (più la precisione).
    Place? best;
    var bestDistance = double.infinity;
    for (final p in places) {
      final d = distanceMeters(p.lat, p.lon, s.lat!, s.lon!);
      if (d < bestDistance) {
        bestDistance = d;
        best = p;
      }
    }
    final w = 1 / math.pow(math.max(s.accuracy ?? 50, 10), 2);
    if (best != null && bestDistance <= placeRadius + (s.accuracy ?? 0)) {
      // Centro come media pesata, con un tetto al peso per seguire i
      // piccoli spostamenti.
      final total = math.min(best.weight, 50 * w) + w;
      best.lat = (best.lat * (total - w) + s.lat! * w) / total;
      best.lon = (best.lon * (total - w) + s.lon! * w) / total;
      best.weight = total;
      best.lastSeen = s.ts;
    } else {
      best = Place(
        id: _nextId++,
        lat: s.lat!,
        lon: s.lon!,
        weight: w,
        firstSeen: s.ts,
        lastSeen: s.ts,
      );
      places.add(best);
    }
    // 3. Il Wi-Fi visto con una buona posizione diventa un'impronta del
    // luogo.
    if (s.wifi != null) {
      best.wifiHits[s.wifi!] = (best.wifiHits[s.wifi!] ?? 0) + 1;
    }
    return best.id;
  }

  /// Unisce i luoghi troppo vicini e toglie quelli abbandonati da tempo.
  void maintain(DateTime now) {
    for (var i = 0; i < places.length; i++) {
      for (var j = places.length - 1; j > i; j--) {
        final a = places[i], b = places[j];
        if (distanceMeters(a.lat, a.lon, b.lat, b.lon) > mergeDistance) {
          continue;
        }
        b.wifiHits.forEach((k, v) => a.wifiHits[k] = (a.wifiHits[k] ?? 0) + v);
        a.weight += b.weight;
        if (b.lastSeen.isAfter(a.lastSeen)) a.lastSeen = b.lastSeen;
        if (b.firstSeen.isBefore(a.firstSeen)) a.firstSeen = b.firstSeen;
        a.userRole ??= b.userRole;
        a.blocked.addAll(b.blocked);
        places.removeAt(j);
      }
    }
    places.removeWhere(
      (p) =>
          p.userRole == null &&
          now.difference(p.lastSeen) > const Duration(days: 90),
    );
  }

  /// Ricalcola i ruoli dai campioni degli ultimi 28 giorni.
  /// [placeOf] dà il luogo di ogni campione (come assegnato da addSample).
  void inferRoles(
    List<LocationSample> samples,
    List<int?> placeOf,
    DateTime now,
  ) {
    scores.clear();
    final start = now.subtract(roleWindow);
    final home = withRole(PlaceRole.home);

    // Campioni utili: nella finestra, con un luogo, non in viaggio.
    final items = <(LocationSample, int)>[];
    for (var i = 0; i < samples.length; i++) {
      final s = samples[i];
      final id = placeOf[i];
      if (id == null || s.ts.isBefore(start)) continue;
      if (home != null &&
          s.lat != null &&
          distanceMeters(home.lat, home.lon, s.lat!, s.lon!) / 1000 >
              travelDistanceKm) {
        continue;
      }
      items.add((s, id));
    }
    items.sort((a, b) => a.$1.ts.compareTo(b.$1.ts));
    if (items.isEmpty) return;

    double decay(DateTime t) =>
        math.pow(0.5, now.difference(t).inHours / (24 * 14)).toDouble();
    // Giornata "da mezzogiorno a mezzogiorno": la notte sta in un solo giorno.
    String nightKey(DateTime t) {
      final s = t.subtract(const Duration(hours: 12));
      return '${s.year}-${s.month}-${s.day}';
    }

    String dayKey(DateTime t) => '${t.year}-${t.month}-${t.day}';

    // --- Sonno: il buco più lungo di ogni notte. ---
    final longest = <String, (Duration, int?, bool, DateTime)>{};
    for (var i = 1; i < items.length; i++) {
      final (a, pa) = items[i - 1];
      final (b, pb) = items[i];
      final gap = b.ts.difference(a.ts);
      if (gap < sleepMinGap || gap > const Duration(hours: 16)) continue;
      final key = nightKey(a.ts);
      final current = longest[key];
      if (current == null || gap > current.$1) {
        longest[key] = (
          gap,
          pa == pb ? pa : null,
          a.charging || b.charging,
          a.ts,
        );
      }
    }
    final sleepW = <int, double>{};
    final chargeW = <int, double>{};
    final sleep14 = <int, int>{};
    var knownSleepW = 0.0;
    for (final (_, place, charging, at) in longest.values) {
      if (place == null) continue;
      final w = decay(at);
      knownSleepW += w;
      sleepW[place] = (sleepW[place] ?? 0) + w;
      if (charging) chargeW[place] = (chargeW[place] ?? 0) + w;
      if (now.difference(at) <= const Duration(days: 14)) {
        sleep14[place] = (sleep14[place] ?? 0) + 1;
      }
    }

    // --- Primo e ultimo campione di ogni giorno. ---
    final byDay = <String, List<(LocationSample, int)>>{};
    for (final it in items) {
      byDay.putIfAbsent(dayKey(it.$1.ts), () => []).add(it);
    }
    final edgeW = <int, double>{};
    var daysW = 0.0;
    for (final list in byDay.values) {
      final w = decay(list.first.$1.ts);
      daysW += w;
      for (final id in {list.first.$2, list.last.$2}) {
        edgeW[id] = (edgeW[id] ?? 0) + w / 2;
      }
    }

    // --- Permanenze (visite): campioni consecutivi nello stesso luogo. ---
    // dwell[place][day] = minuti; arrivals[place] = minuto del primo arrivo
    // nei giorni feriali.
    final dwell = <int, Map<String, double>>{};
    final arrivals = <int, List<int>>{};
    final firstArrivalDay = <int, Set<String>>{};
    for (var i = 0; i < items.length; i++) {
      final (s, id) = items[i];
      final day = dayKey(s.ts);
      final next = i + 1 < items.length ? items[i + 1] : null;
      if (next != null &&
          next.$2 == id &&
          next.$1.ts.difference(s.ts) <= visitMaxGap &&
          dayKey(next.$1.ts) == day) {
        dwell.putIfAbsent(id, () => {})[day] =
            (dwell[id]![day] ?? 0) +
            next.$1.ts.difference(s.ts).inMinutes.toDouble();
      }
      if (dayTypeFor(s.ts) == DayType.workday &&
          firstArrivalDay.putIfAbsent(id, () => {}).add(day)) {
        arrivals.putIfAbsent(id, () => []).add(s.ts.hour * 60 + s.ts.minute);
      }
    }

    // --- Punteggi. ---
    final homeConf = <int, double>{};
    final workConf = <int, double>{};
    for (final p in places) {
      final nights = sleepW[p.id] ?? 0;
      final sleepShare = knownSleepW == 0 ? 0.0 : nights / knownSleepW;
      final chargeShare = nights == 0 ? 0.0 : (chargeW[p.id] ?? 0) / nights;
      final edgeShare = daysW == 0 ? 0.0 : (edgeW[p.id] ?? 0) / daysW;
      final homeScore = 0.6 * sleepShare + 0.2 * chargeShare + 0.2 * edgeShare;
      final homeEvidence = math.min(1.0, (sleep14[p.id] ?? 0) / 4);
      homeConf[p.id] = (sleep14[p.id] ?? 0) >= 3
          ? _sigmoid(10 * (homeScore - 0.5)) * homeEvidence
          : 0;
    }
    final homeCandidate = _pick(PlaceRole.home, homeConf);

    // Minuti feriali totali (esclusa casa), per la quota del lavoro.
    double workdayMinutes(int id) {
      var sum = 0.0;
      dwell[id]?.forEach((day, minutes) {
        final parts = day.split('-').map(int.parse).toList();
        final d = DateTime(parts[0], parts[1], parts[2]);
        if (dayTypeFor(d) == DayType.workday) {
          sum += minutes * decay(d);
        }
      });
      return sum;
    }

    final totalWorkday = [
      for (final p in places)
        if (p.id != homeCandidate?.id) workdayMinutes(p.id),
    ].fold(0.0, (a, b) => a + b);

    for (final p in places) {
      if (p.id == homeCandidate?.id) continue;
      if (homeCandidate != null &&
          distanceMeters(p.lat, p.lon, homeCandidate.lat, homeCandidate.lon) <
              250) {
        continue;
      }
      final days = dwell[p.id] ?? const {};
      var workdayDays = 0, weekendDays = 0;
      var workdaySum = 0.0, weekendSum = 0.0;
      var presence14 = 0;
      days.forEach((day, minutes) {
        final parts = day.split('-').map(int.parse).toList();
        final d = DateTime(parts[0], parts[1], parts[2]);
        if (dayTypeFor(d) == DayType.workday) {
          workdayDays++;
          workdaySum += minutes;
          if (minutes >= 120 && now.difference(d) <= const Duration(days: 14)) {
            presence14++;
          }
        } else {
          weekendDays++;
          weekendSum += minutes;
        }
      });
      final weekdayShare = totalWorkday == 0
          ? 0.0
          : workdayMinutes(p.id) / totalWorkday;
      final weekendRatio = workdayDays == 0
          ? 1.0
          : (weekendDays == 0 ? 0.0 : weekendSum / weekendDays) /
                (workdaySum / workdayDays);
      final arr = arrivals[p.id] ?? const [];
      var regularity = 0.0;
      if (arr.length >= 2) {
        final mean = arr.reduce((a, b) => a + b) / arr.length;
        final variance =
            arr.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) /
            arr.length;
        regularity = 1 - math.min(1.0, math.sqrt(variance) / 120);
      }
      final score =
          0.5 * weekdayShare +
          0.2 * (1 - math.min(1.0, weekendRatio)) +
          0.3 * regularity;
      final evidence = math.min(1.0, presence14 / 5);
      workConf[p.id] = presence14 >= 3
          ? _sigmoid(10 * (score - 0.45)) * evidence
          : 0;
    }
    final workCandidate = _pick(PlaceRole.work, workConf);

    // --- Assegnazione, con isteresi e correzioni dell'utente. ---
    final distinctDays = <int, Set<String>>{};
    for (final (s, id) in items) {
      distinctDays.putIfAbsent(id, () => {}).add(dayKey(s.ts));
    }
    for (final p in places) {
      scores[p.id] = PlaceScores(
        homeConf[p.id] ?? 0,
        workConf[p.id] ?? 0,
        distinctDays[p.id]?.length ?? 0,
      );
      if (p.id == homeCandidate?.id) {
        p
          ..role = PlaceRole.home
          ..roleConfidence = homeConf[p.id]!;
      } else if (p.id == workCandidate?.id) {
        p
          ..role = PlaceRole.work
          ..roleConfidence = workConf[p.id]!;
      } else if ((distinctDays[p.id]?.length ?? 0) >= 3) {
        p
          ..role = PlaceRole.frequent
          ..roleConfidence = 0;
      } else {
        p
          ..role = PlaceRole.none
          ..roleConfidence = 0;
      }
    }
  }

  /// Il luogo che prende [role]: il ruolo scelto dall'utente vince; poi il
  /// migliore sopra soglia, ma il titolare attuale cede solo se il nuovo lo
  /// supera di [roleHysteresis].
  Place? _pick(PlaceRole role, Map<int, double> conf) {
    for (final p in places) {
      if (p.userRole == role) return p;
    }
    Place? best;
    var bestConf = roleThreshold;
    for (final p in places) {
      if (p.blocked.contains(role) || p.userRole != null) continue;
      final c = conf[p.id] ?? 0;
      if (c >= bestConf) {
        best = p;
        bestConf = c;
      }
    }
    Place? holder;
    for (final p in places) {
      if (p.role == role && p.userRole == null) holder = p;
    }
    if (holder != null &&
        best != null &&
        holder.id != best.id &&
        (conf[holder.id] ?? 0) >= roleThreshold &&
        bestConf < (conf[holder.id] ?? 0) + roleHysteresis) {
      return holder;
    }
    return best;
  }

  /// Correzioni dell'utente sul luogo [id].
  void setUserRole(int id, PlaceRole? role) {
    for (final p in places) {
      if (role != null && p.userRole == role && p.id != id) p.userRole = null;
    }
    final p = byId(id);
    if (p == null) return;
    p.userRole = role;
    if (role != null) p.blocked.remove(role);
  }

  void block(int id, PlaceRole role) {
    final p = byId(id);
    if (p == null) return;
    p.blocked.add(role);
    if (p.userRole == role) p.userRole = null;
    if (p.role == role) p.role = PlaceRole.none;
  }

  void reset() => places.clear();
}
