import 'package:flutter/material.dart';

import '../glide_style.dart';
import '../labels.dart';
import '../scope.dart';
import '../widgets/app_icon.dart';
import 'settings_widgets.dart';

/// Hidden apps and categories, with restore.
class HiddenPage extends StatelessWidget {
  const HiddenPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final settings = scope.settings;
    final controller = scope.controller;
    final l = context.l10n;
    final c = GlideColors.of(context);

    Widget empty(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Text(text, style: TextStyle(color: c.muted)),
    );

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final apps = [
          for (final id in settings.hiddenApps) ?controller.byId(id),
        ]..sort((a, b) => a.sortKey.compareTo(b.sortKey));
        final categories = settings.hiddenCategories.toList()
          ..sort((a, b) => a.index.compareTo(b.index));

        return SettingsScaffold(
          title: l.hiddenApps,
          children: [
            SettingsSection(
              icon: Icons.visibility_off_outlined,
              title: l.hiddenApps,
              children: [
                if (apps.isEmpty)
                  empty(l.hiddenAppsEmpty)
                else
                  for (final app in apps)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(cardPadding, 6, 8, 6),
                      child: Row(
                        children: [
                          AppIconView(app: app, size: 36),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              app.label,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => settings.setHidden(app.id, false),
                            child: Text(l.restore),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
            SettingsSection(
              icon: Icons.category_outlined,
              title: l.hiddenCategories,
              children: [
                if (categories.isEmpty)
                  empty(l.hiddenCategoriesEmpty)
                else
                  for (final cat in categories)
                    SettingsTile(
                      icon: categoryIcon(cat),
                      title: categoryLabel(l, cat),
                      trailing: TextButton(
                        onPressed: () => settings.setCategoryHidden(cat, false),
                        child: Text(l.restore),
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
