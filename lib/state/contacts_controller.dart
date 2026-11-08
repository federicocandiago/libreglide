/// Contacts panel: favorites (starred) and libreGLIDE's most used.
///
/// Android no longer tracks "frequent" contacts (since Android 10), so
/// libreGLIDE computes "most used" itself, locally, from the contacts opened
/// from the panel.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../core/contact.dart';
import '../data/launch_store.dart';
import '../platform/launcher_bridge.dart';

class ContactsController extends ChangeNotifier {
  ContactsController(this._bridge, this._store, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final LauncherBridge _bridge;
  final LaunchStore _store;
  final DateTime Function() _clock;

  bool? permission;
  bool loading = false;

  /// Most used first, then starred contacts not used yet (alphabetically).
  /// At most [maxShown].
  List<Contact> favorites = const [];
  static const maxShown = 12;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    try {
      permission = await _bridge.hasContacts();
      if (permission!) {
        final top = await _store.topContacts(_clock(), n: maxShown);
        final used = await _bridge.contactsByLookup([
          for (final t in top) t.$1,
        ]);
        final byKey = {for (final c in used) c.lookupKey: c};
        final starred = await _bridge.starredContacts();
        final out = <Contact>[for (final t in top) ?byKey[t.$1]];
        for (final c in starred) {
          if (out.length >= maxShown) break;
          if (!out.any((o) => o.lookupKey == c.lookupKey)) out.add(c);
        }
        favorites = out;
      }
    } catch (e) {
      debugPrint('libreglide: contacts unavailable: $e');
    }
    loading = false;
    notifyListeners();
  }

  Future<void> requestPermission() => _bridge.requestContacts();

  /// Contacts matching [query], best match first (see [rankContacts]).
  Future<List<Contact>> search(String query) async {
    final results = await _bridge.searchContacts(query);
    final usage = {
      for (final (key, weight) in await _store.topContacts(_clock(), n: 500))
        key: weight,
    };
    return rankContacts(results, query, usage: usage);
  }

  final Map<int, Future<ImageProvider?>> _photos = {};

  /// Photo of [c], loaded once and kept: while typing the same contacts come
  /// back without reading or decoding their photo again.
  Future<ImageProvider?> photo(Contact c) {
    if (!c.hasPhoto) return Future.value();
    return _photos[c.id] ??= _bridge
        .contactPhoto(c.id)
        .then<ImageProvider?>((b) => b == null ? null : MemoryImage(b))
        .catchError((Object _) => null);
  }

  Future<void> _used(Contact c) => _store.recordContact(c.lookupKey, _clock());

  Future<void> dial(Contact c) async {
    if (c.number == null) return;
    await _used(c);
    await _bridge.dial(c.number!);
  }

  Future<void> sms(Contact c) async {
    if (c.number == null) return;
    await _used(c);
    await _bridge.sms(c.number!);
  }

  Future<void> open(Contact c) async {
    await _used(c);
    await _bridge.openContact(c);
  }
}
