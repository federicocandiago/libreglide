import 'package:flutter/material.dart';

import '../../core/app_entry.dart';
import '../../core/categories.dart';
import '../../data/settings.dart';
import '../labels.dart';
import '../scope.dart';
import 'app_icon.dart';

/// Azioni su un'app (spec-viste-app §5).
Future<void> showAppActions(BuildContext context, AppEntry app) {
  final scope = AppScope.of(context);
  final controller = scope.controller;
  final settings = scope.settings;
  final l = context.l10n;
  final messenger = ScaffoldMessenger.maybeOf(context);

  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (sheetContext) {
      final isFavorite = settings.isFavorite(app.id);
      final category = controller.categoryOf(app);
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: AppIconView(app: app, size: 44),
              title: Text(
                app.label,
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              subtitle: Text(categoryLabel(l, category)),
            ),
            const Divider(indent: 24, endIndent: 24),
            ListTile(
              leading: Icon(
                isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              ),
              title: Text(isFavorite ? l.removeFavorite : l.addToDock),
              onTap: () {
                Navigator.pop(sheetContext);
                if (!isFavorite && settings.favoritesFull) {
                  messenger?.showSnackBar(
                    SnackBar(
                      content: Text(
                        l.favoritesFull(SettingsController.maxFavorites),
                      ),
                    ),
                  );
                  return;
                }
                settings.setFavorite(app.id, !isFavorite);
              },
            ),
            ListTile(
              leading: const Icon(Icons.category_rounded),
              title: Text(l.changeCategory),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickCategory(context, app);
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility_off_rounded),
              title: Text(l.hideApp),
              onTap: () {
                Navigator.pop(sheetContext);
                settings.setHidden(app.id, true);
                messenger?.showSnackBar(
                  SnackBar(
                    content: Text(l.appHidden(app.label)),
                    action: SnackBarAction(
                      label: l.undo,
                      onPressed: () => settings.setHidden(app.id, false),
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: Text(l.appInfo),
              onTap: () {
                Navigator.pop(sheetContext);
                controller.openAppInfo(app);
              },
            ),
            if (!app.isSystem)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded),
                title: Text(l.uninstall),
                onTap: () {
                  Navigator.pop(sheetContext);
                  controller.uninstall(app);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

Future<void> _pickCategory(BuildContext context, AppEntry app) {
  final scope = AppScope.of(context);
  final settings = scope.settings;
  final l = context.l10n;
  final override = settings.categoryOverrides[app.packageName];

  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, scrollController) => RadioGroup<AppCategory?>(
        groupValue: override,
        onChanged: (value) {
          Navigator.pop(sheetContext);
          settings.setCategoryOverride(app.packageName, value);
        },
        child: ListView(
          controller: scrollController,
          children: [
            RadioListTile<AppCategory?>(
              value: null,
              title: Text(l.automaticCategory),
              secondary: const Icon(Icons.auto_awesome_rounded),
            ),
            const Divider(indent: 24, endIndent: 24),
            for (final c in defaultCategoryOrder)
              RadioListTile<AppCategory?>(
                value: c,
                title: Text(categoryLabel(l, c)),
                secondary: Icon(categoryIcon(c)),
              ),
          ],
        ),
      ),
    ),
  );
}
