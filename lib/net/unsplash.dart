/// Unsplash client: one of the only two places in the app that use the
/// network (the other is `open_meteo.dart`).
///
/// Called only if the user has entered their own key and enabled the
/// contextual wallpaper. Sends only generic keywords ("sunset autumn"), the
/// key and the usual technical connection data: no location and no phone
/// usage data (see the privacy policy).
///
/// Unsplash guidelines followed:
/// - photos are loaded from the URLs returned by the API (hotlinking);
/// - when a photo is used, its `download_location` is called;
/// - the author and Unsplash are credited with links and UTM parameters.
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

  /// URL of the image resized by Unsplash for the screen.
  String imageUrl(int width) =>
      '$rawUrl${rawUrl.contains('?') ? '&' : '?'}w=$width&q=80&fm=jpg&fit=max';
}

/// UTM parameters required for attribution links.
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
      throw UnsplashException('invalid key', invalidKey: true);
    }
    if (r.statusCode != 200) {
      throw UnsplashException('response ${r.statusCode}');
    }
  }

  /// First [perPage] portrait photos for [query], with a high content filter.
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

  /// Checks the key with a minimal search.
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

  /// Tells Unsplash the photo was used (required).
  Future<void> trackDownload(UnsplashPhoto photo) async {
    try {
      await _http
          .get(Uri.parse(photo.downloadLocation), headers: _headers)
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      // A failed report must not block the wallpaper.
    }
  }

  void close() => _http.close();
}
