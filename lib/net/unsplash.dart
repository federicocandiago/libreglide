/// Client Unsplash: l'UNICO punto dell'app che usa la rete.
///
/// Viene chiamato solo se l'utente ha inserito una propria chiave e attivato
/// lo sfondo contestuale. Invia soltanto parole chiave generiche ("sunset
/// autumn"), la chiave e i normali dati tecnici della connessione: nessuna
/// posizione e nessun dato d'uso del telefono (vedi informativa privacy).
///
/// Regole Unsplash rispettate:
/// - le foto si scaricano dagli URL restituiti dall'API (hotlink);
/// - quando una foto viene usata si chiama il suo `download_location`;
/// - autore e Unsplash sono citati con link e parametri UTM.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class UnsplashException implements Exception {
  const UnsplashException(this.message, {this.invalidKey = false});
  final String message;
  final bool invalidKey;

  @override
  String toString() => 'UnsplashException: $message';
}

class UnsplashPhoto {
  const UnsplashPhoto({
    required this.id,
    required this.rawUrl,
    required this.authorName,
    required this.authorUrl,
    required this.photoUrl,
    required this.downloadLocation,
  });

  factory UnsplashPhoto.fromJson(Map<String, dynamic> j) {
    final user = j['user'] as Map<String, dynamic>;
    final links = j['links'] as Map<String, dynamic>;
    final urls = j['urls'] as Map<String, dynamic>;
    return UnsplashPhoto(
      id: j['id'] as String,
      rawUrl: urls['raw'] as String,
      authorName: (user['name'] as String?) ?? (user['username'] as String),
      authorUrl: (user['links'] as Map<String, dynamic>)['html'] as String,
      photoUrl: links['html'] as String,
      downloadLocation: links['download_location'] as String,
    );
  }

  final String id;
  final String rawUrl;
  final String authorName;
  final String authorUrl;
  final String photoUrl;
  final String downloadLocation;

  /// URL dell'immagine ridimensionata da Unsplash per lo schermo.
  String imageUrl(int width) =>
      '$rawUrl${rawUrl.contains('?') ? '&' : '?'}w=$width&q=80&fm=jpg&fit=max';
}

/// Parametri UTM richiesti per i link di attribuzione.
String withUtm(String url) =>
    '$url${url.contains('?') ? '&' : '?'}utm_source=libreglide&utm_medium=referral';

class UnsplashClient {
  UnsplashClient(this.accessKey, {http.Client? client})
    : _http = client ?? http.Client();

  final String accessKey;
  final http.Client _http;

  static const _api = 'api.unsplash.com';

  Map<String, String> get _headers => {
    'Authorization': 'Client-ID $accessKey',
    'Accept-Version': 'v1',
  };

  void _check(http.Response r) {
    if (r.statusCode == 401 || r.statusCode == 403) {
      throw UnsplashException('chiave non valida', invalidKey: true);
    }
    if (r.statusCode != 200) {
      throw UnsplashException('risposta ${r.statusCode}');
    }
  }

  /// Prime [perPage] foto verticali per [query], filtro contenuti alto.
  Future<List<UnsplashPhoto>> search(String query, {int perPage = 10}) async {
    final uri = Uri.https(_api, '/search/photos', {
      'query': query,
      'per_page': '$perPage',
      'orientation': 'portrait',
      'content_filter': 'high',
    });
    final r = await _http
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 15));
    _check(r);
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    return [
      for (final p in body['results'] as List<dynamic>)
        UnsplashPhoto.fromJson(p as Map<String, dynamic>),
    ];
  }

  /// Verifica la chiave con una ricerca minima.
  Future<bool> validate() async {
    try {
      await search('nature', perPage: 1);
      return true;
    } on UnsplashException catch (e) {
      if (e.invalidKey) return false;
      rethrow;
    }
  }

  Future<Uint8List> download(UnsplashPhoto photo, {int width = 1440}) async {
    final r = await _http
        .get(Uri.parse(photo.imageUrl(width)))
        .timeout(const Duration(seconds: 30));
    _check(r);
    return r.bodyBytes;
  }

  /// Segnala a Unsplash che la foto è stata usata (obbligatorio).
  Future<void> trackDownload(UnsplashPhoto photo) async {
    try {
      await _http
          .get(Uri.parse(photo.downloadLocation), headers: _headers)
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      // Non blocca lo sfondo se la segnalazione fallisce.
    }
  }

  void close() => _http.close();
}
