import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../legal/privacy_policy.dart';
import '../glide_style.dart';
import '../labels.dart';
import 'settings_widgets.dart';

/// Informativa sulla privacy, divisa in card.
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final c = GlideColors.of(context);
    final sections = privacyPolicy(lang);
    return SettingsScaffold(
      title: context.l10n.privacyPolicy,
      children: [
        for (final (i, s) in sections.indexed)
          FlatCard(
            color: i == 0
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CapsHeader(
                  icon: i == 0
                      ? Icons.verified_user_rounded
                      : Icons.article_outlined,
                  label: s.title,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final p in s.paragraphs)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: SelectableText(
                            p,
                            style: TextStyle(
                              fontSize: 14.5,
                              height: 1.45,
                              color: i == 0
                                  ? Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            context.l10n.version('$policyVersion · $policyDate'),
            style: TextStyle(color: c.muted, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

/// Librerie open source: l'elenco raccolto da Flutter (LicenseRegistry).
class OpenSourcePage extends StatefulWidget {
  const OpenSourcePage({super.key});

  @override
  State<OpenSourcePage> createState() => _OpenSourcePageState();
}

class _OpenSourcePageState extends State<OpenSourcePage> {
  late final Future<Map<String, List<String>>> _licenses = _load();

  static Future<Map<String, List<String>>> _load() async {
    final out = <String, List<String>>{};
    await for (final entry in LicenseRegistry.licenses) {
      final text = entry.paragraphs.map((p) => p.text).join('\n\n');
      for (final package in entry.packages) {
        out.putIfAbsent(package, () => []).add(text);
      }
    }
    return Map.fromEntries(
      out.entries.toList()
        ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase())),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = GlideColors.of(context);
    return FutureBuilder<Map<String, List<String>>>(
      future: _licenses,
      builder: (context, snap) {
        final data = snap.data;
        return SettingsScaffold(
          title: l.openSource,
          children: [
            SettingsSection(
              icon: Icons.auto_awesome_rounded,
              title: 'libreGLIDE',
              children: [
                SettingsTile(
                  icon: Icons.gavel_rounded,
                  title: l.appLicense,
                  subtitle: l.appLicenseUndefined,
                ),
                SettingsTile(
                  icon: Icons.photo_outlined,
                  title: 'Unsplash',
                  subtitle: l.unsplashAttribution,
                ),
              ],
            ),
            if (data == null)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              SettingsSection(
                icon: Icons.code_rounded,
                title: l.openSourceCount(data.length),
                children: [
                  for (final e in data.entries)
                    SettingsTile(
                      icon: Icons.inventory_2_outlined,
                      title: e.key,
                      subtitle: e.value.length == 1
                          ? null
                          : l.licenseCount(e.value.length),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: c.muted,
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              _LicenseText(package: e.key, texts: e.value),
                        ),
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

class _LicenseText extends StatelessWidget {
  const _LicenseText({required this.package, required this.texts});

  final String package;
  final List<String> texts;

  @override
  Widget build(BuildContext context) => SettingsScaffold(
    title: package,
    children: [
      for (final t in texts)
        FlatCard(
          padding: const EdgeInsets.all(16),
          child: SelectableText(
            t,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
        ),
    ],
  );
}
