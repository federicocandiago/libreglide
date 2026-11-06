import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_entry.dart';
import '../../core/categories.dart';
import '../../core/detox.dart';
import '../glide_style.dart';
import '../labels.dart';
import '../scope.dart';
import '../widgets/app_icon.dart';
import 'settings_widgets.dart';

/// Apre Digital detox. Se è acceso serve il PIN: è l'unico modo per
/// spegnerlo o allentarlo da dentro libreGLIDE.
Future<void> openDetox(BuildContext context) async {
  final scope = AppScope.of(context);
  if (scope.settings.detoxEnabled &&
      await scope.controller.bridge.detoxHasPin()) {
    if (!context.mounted) return;
    if (!await askDetoxPin(context)) return;
  }
  if (!context.mounted) return;
  await Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const DetoxPage()));
}

/// Chiede il PIN; true se è giusto.
Future<bool> askDetoxPin(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (_) => const _AskPinDialog(),
    ) ??
    false;

String _formatMinutes(BuildContext context, int m) =>
    MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: m ~/ 60, minute: m % 60),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );

/// Digital detox: interruttore, PIN, orario, sblocco, app bloccate.
class DetoxPage extends StatefulWidget {
  const DetoxPage({super.key});

  @override
  State<DetoxPage> createState() => _DetoxPageState();
}

class _DetoxPageState extends State<DetoxPage> {
  bool _hasPin = false;
  bool? _serviceOn;
  StreamSubscription<void>? _resumed;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_resumed != null) return;
    // Tornando dalle impostazioni di accessibilità lo stato va riletto.
    _resumed = AppScope.of(context).controller.bridge.resumed
        .listen((_) => _refresh());
    _refresh();
  }

  @override
  void dispose() {
    _resumed?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final bridge = AppScope.of(context).controller.bridge;
    final pin = await bridge.detoxHasPin();
    final service = await bridge.detoxServiceEnabled();
    if (mounted) {
      setState(() {
        _hasPin = pin;
        _serviceOn = service;
      });
    }
  }

  Future<bool> _setPin() async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => _SetPinDialog(change: _hasPin),
        ) ??
        false;
    if (ok) await _refresh();
    return ok;
  }

  Future<void> _toggle(bool on) async {
    final scope = AppScope.of(context);
    if (!on) {
      scope.settings.setDetoxEnabled(false);
      return;
    }
    // Senza PIN il detox non si accende: è lui a proteggere le impostazioni.
    if (!_hasPin && !await _setPin()) return;
    scope.settings.setDetoxEnabled(true);
    if (_serviceOn != true && mounted) await _explainService();
  }

  Future<void> _explainService() async {
    final l = context.l10n;
    final bridge = AppScope.of(context).controller.bridge;
    final go = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        icon: const Icon(Icons.accessibility_new_rounded),
        title: Text(l.detoxServiceTitle),
        content: Text(l.detoxServiceExplain),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(l.notNow),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(l.detoxServiceOpen),
          ),
        ],
      ),
    );
    if (go == true) await bridge.openDetoxService();
  }

  Future<void> _pickTime(bool start) async {
    final settings = AppScope.of(context).settings;
    final m = start ? settings.detoxStart : settings.detoxEnd;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: m ~/ 60, minute: m % 60),
    );
    if (picked == null) return;
    final v = picked.hour * 60 + picked.minute;
    start
        ? settings.setDetoxSchedule(start: v)
        : settings.setDetoxSchedule(end: v);
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.of(context).settings;
    final l = context.l10n;
    final c = GlideColors.of(context);
    const chevron = Icon(Icons.chevron_right_rounded);

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final on = settings.detoxEnabled;
        return SettingsScaffold(
          title: l.detoxTitle,
          children: [
            FlatCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 4),
                  SettingsSwitchTile(
                    icon: Icons.beach_access_rounded,
                    title: l.detoxTitle,
                    subtitle: l.detoxDesc,
                    value: on,
                    onChanged: _toggle,
                  ),
                  if (on && _serviceOn == false) ...[
                    Divider(height: 1, indent: 72, color: c.hairline),
                    SettingsTile(
                      icon: Icons.accessibility_new_rounded,
                      danger: true,
                      title: l.detoxServiceOff,
                      subtitle: l.detoxServiceOffDesc,
                      onTap: _explainService,
                      trailing: const Icon(Icons.open_in_new_rounded),
                    ),
                  ],
                  if (on && _serviceOn == true) ...[
                    Divider(height: 1, indent: 72, color: c.hairline),
                    SettingsTile(
                      icon: Icons.check_circle_rounded,
                      title: l.detoxServiceOn,
                      subtitle:
                          settings.detoxSchedule.isActiveAt(DateTime.now())
                          ? l.detoxActiveNow
                          : l.detoxStartsAt(
                              _formatMinutes(context, settings.detoxStart),
                            ),
                    ),
                  ],
                ],
              ),
            ),
            SettingsSection(
              icon: Icons.password_rounded,
              title: l.detoxPin,
              children: [
                SettingsTile(
                  icon: Icons.pin_rounded,
                  title: _hasPin ? l.detoxChangePin : l.detoxSetPin,
                  subtitle: l.detoxPinDesc,
                  trailing: chevron,
                  onTap: _setPin,
                ),
              ],
            ),
            SettingsSection(
              icon: Icons.schedule_rounded,
              title: l.detoxSchedule,
              children: [
                SettingsChoiceTile<bool>(
                  icon: Icons.schedule_rounded,
                  title: l.detoxWhen,
                  options: [
                    (true, l.detoxAllDay, Icons.all_inclusive_rounded),
                    (false, l.detoxTimeRange, Icons.timelapse_rounded),
                  ],
                  selected: settings.detoxAllDay,
                  onChanged: (v) => settings.setDetoxSchedule(allDay: v),
                ),
                if (!settings.detoxAllDay) ...[
                  SettingsTile(
                    icon: Icons.play_circle_outline_rounded,
                    title: l.detoxFrom,
                    subtitle: _formatMinutes(context, settings.detoxStart),
                    onTap: () => _pickTime(true),
                  ),
                  SettingsTile(
                    icon: Icons.stop_circle_outlined,
                    title: l.detoxTo,
                    subtitle: _formatMinutes(context, settings.detoxEnd),
                    onTap: () => _pickTime(false),
                  ),
                ],
              ],
            ),
            SettingsSection(
              icon: Icons.lock_open_rounded,
              title: l.detoxUnlock,
              children: [
                SettingsChoiceTile<bool>(
                  icon: Icons.lock_open_rounded,
                  title: l.detoxUnlockTitle,
                  subtitle: settings.detoxUnlockable
                      ? l.detoxUnlockPinDesc
                      : l.detoxUnlockNeverDesc,
                  options: [
                    (true, l.detoxUnlockPin, Icons.pin_rounded),
                    (false, l.detoxUnlockNever, Icons.block_rounded),
                  ],
                  selected: settings.detoxUnlockable,
                  onChanged: settings.setDetoxUnlockable,
                ),
              ],
            ),
            SettingsSection(
              icon: Icons.apps_rounded,
              title: l.detoxApps,
              children: [
                SettingsTile(
                  icon: Icons.lock_rounded,
                  title: l.detoxLockedApps,
                  subtitle: l.detoxAppsCount(settings.detoxApps.length),
                  trailing: chevron,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const DetoxAppsPage(),
                    ),
                  ),
                ),
                SettingsSwitchTile(
                  icon: Icons.visibility_off_rounded,
                  title: l.detoxHide,
                  subtitle: l.detoxHideDesc,
                  value: settings.detoxHideApps,
                  onChanged: settings.setDetoxHideApps,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 18, color: c.muted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.detoxEmergency,
                      style: TextStyle(
                        color: c.muted,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Scelta delle app da bloccare, per gruppi: spuntare un gruppo blocca
/// tutte le sue app, poi si correggono una per una. In cima le app di
/// sistema delicate (installazione, Impostazioni, Play Store).
class DetoxAppsPage extends StatefulWidget {
  const DetoxAppsPage({super.key});

  @override
  State<DetoxAppsPage> createState() => _DetoxAppsPageState();
}

class _DetoxAppsPageState extends State<DetoxAppsPage> {
  List<(String, String)> _system = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_system.isNotEmpty) return;
    AppScope.of(context).controller.bridge.detoxSystemApps().then((list) {
      if (mounted) setState(() => _system = list);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final settings = scope.settings;
    final controller = scope.controller;
    final l = context.l10n;

    // Un'app per pacchetto (il blocco vale per tutto il pacchetto), divise
    // per categoria; libreGLIDE non si può bloccare.
    final byCategory = <AppCategory, List<AppEntry>>{};
    final seen = <String>{};
    for (final a in controller.allApps) {
      if (a.packageName == 'org.libreglide.launcher') continue;
      if (!seen.add(a.packageName)) continue;
      byCategory.putIfAbsent(controller.categoryOf(a), () => []).add(a);
    }
    final categories = byCategory.keys.toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => SettingsScaffold(
        title: l.detoxLockedApps,
        children: [
          if (_system.isNotEmpty)
            _Group(
              icon: Icons.admin_panel_settings_rounded,
              title: l.detoxSystemGroup,
              subtitle: l.detoxSystemGroupDesc,
              items: [
                for (final (pkg, label) in _system)
                  (pkg, label, controller.byPackage(pkg)),
              ],
            ),
          for (final cat in categories)
            _Group(
              icon: categoryIcon(cat),
              title: categoryLabel(l, cat),
              items: [
                for (final a in byCategory[cat]!) (a.packageName, a.label, a),
              ],
            ),
        ],
      ),
    );
  }
}

/// Un gruppo di app: la spunta del gruppo è un contenitore (tutte,
/// nessuna, alcune); la freccia mostra le singole app.
class _Group extends StatefulWidget {
  const _Group({
    required this.icon,
    required this.title,
    required this.items,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// (pacchetto, nome, app per l'icona).
  final List<(String, String, AppEntry?)> items;

  @override
  State<_Group> createState() => _GroupState();
}

class _GroupState extends State<_Group> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.of(context).settings;
    final l = context.l10n;
    final c = GlideColors.of(context);
    final packages = [for (final (p, _, _) in widget.items) p];
    final locked = packages.where(settings.detoxApps.contains).length;
    final bool? all = locked == 0
        ? false
        : locked == packages.length
        ? true
        : null;

    return FlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(cardPadding, 12, 4, 12),
              child: Row(
                children: [
                  TonalIcon(widget.icon),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          widget.subtitle ??
                              l.detoxGroupCount(locked, packages.length),
                          style: TextStyle(color: c.muted, fontSize: 13.5),
                        ),
                      ],
                    ),
                  ),
                  Checkbox(
                    tristate: true,
                    value: all,
                    // Tutte bloccate → si sbloccano; altrimenti si bloccano tutte.
                    onChanged: (_) =>
                        settings.setDetoxApps(packages, all != true),
                  ),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more_rounded, color: c.muted),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: !_open
                ? const SizedBox(width: double.infinity)
                : Column(
                    children: [
                      Divider(height: 1, color: c.hairline),
                      for (final (pkg, label, app) in widget.items)
                        InkWell(
                          onTap: () => settings.setDetoxApps([
                            pkg,
                          ], !settings.detoxApps.contains(pkg)),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              cardPadding + 4,
                              6,
                              4,
                              6,
                            ),
                            child: Row(
                              children: [
                                if (app != null)
                                  AppIconView(app: app, size: 34)
                                else
                                  SizedBox(
                                    width: 34,
                                    height: 34,
                                    child: Icon(
                                      Icons.android_rounded,
                                      color: c.muted,
                                    ),
                                  ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    label,
                                    style: const TextStyle(fontSize: 15.5),
                                  ),
                                ),
                                Checkbox(
                                  value: settings.detoxApps.contains(pkg),
                                  onChanged: (v) =>
                                      settings.setDetoxApps([pkg], v ?? false),
                                ),
                                const SizedBox(width: 30),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 6),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Richiesta del PIN per entrare nelle impostazioni del detox.
class _AskPinDialog extends StatefulWidget {
  const _AskPinDialog();

  @override
  State<_AskPinDialog> createState() => _AskPinDialogState();
}

class _AskPinDialogState extends State<_AskPinDialog> {
  final _pin = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_pin.text.isEmpty || _busy) return;
    final l = context.l10n;
    setState(() => _busy = true);
    final r = await AppScope.of(context).controller.bridge
        .detoxCheckPin(_pin.text);
    if (!mounted) return;
    if (r == 0) {
      Navigator.pop(context, true);
      return;
    }
    _pin.clear();
    setState(() {
      _busy = false;
      _error = r < 0 ? l.detoxWrongPin : l.detoxWait((r / 1000).ceil());
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      icon: const Icon(Icons.beach_access_rounded),
      title: Text(l.detoxTitle),
      content: TextField(
        controller: _pin,
        autofocus: true,
        obscureText: true,
        maxLength: 16,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          labelText: l.detoxPinLabel,
          errorText: _error,
          counterText: '',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l.cancel),
        ),
        FilledButton(onPressed: _busy ? null : _submit, child: Text(l.ok)),
      ],
    );
  }
}

/// Imposta o cambia il PIN (per cambiarlo serve quello attuale).
class _SetPinDialog extends StatefulWidget {
  const _SetPinDialog({required this.change});

  final bool change;

  @override
  State<_SetPinDialog> createState() => _SetPinDialogState();
}

class _SetPinDialogState extends State<_SetPinDialog> {
  final _old = TextEditingController();
  final _pin = TextEditingController();
  final _confirm = TextEditingController();
  String? _oldError;
  String? _pinError;
  String? _confirmError;
  bool _busy = false;

  @override
  void dispose() {
    _old.dispose();
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = context.l10n;
    final bridge = AppScope.of(context).controller.bridge;
    setState(() {
      _oldError = null;
      _pinError = validDetoxPin(_pin.text) ? null : l.detoxPinLength;
      _confirmError = _pin.text == _confirm.text ? null : l.detoxPinMismatch;
    });
    if (_pinError != null || _confirmError != null) return;
    setState(() => _busy = true);
    if (widget.change) {
      final r = await bridge.detoxCheckPin(_old.text);
      if (!mounted) return;
      if (r != 0) {
        _old.clear();
        setState(() {
          _busy = false;
          _oldError = r < 0 ? l.detoxWrongPin : l.detoxWait((r / 1000).ceil());
        });
        return;
      }
    }
    await bridge.detoxSetPin(_pin.text);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    InputDecoration field(String label, String? error) =>
        InputDecoration(labelText: label, errorText: error, counterText: '');
    return AlertDialog(
      icon: const Icon(Icons.pin_rounded),
      title: Text(widget.change ? l.detoxChangePin : l.detoxSetPin),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.change)
              TextField(
                controller: _old,
                obscureText: true,
                maxLength: 16,
                autofocus: true,
                decoration: field(l.detoxOldPin, _oldError),
              ),
            TextField(
              controller: _pin,
              obscureText: true,
              maxLength: 16,
              autofocus: !widget.change,
              decoration: field(l.detoxNewPin, _pinError),
            ),
            TextField(
              controller: _confirm,
              obscureText: true,
              maxLength: 16,
              onSubmitted: (_) => _save(),
              decoration: field(l.detoxConfirmPin, _confirmError),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: BorderRadius.circular(innerRadius),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: scheme.onErrorContainer,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.detoxPinWarning,
                      style: TextStyle(
                        color: scheme.onErrorContainer,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l.cancel),
        ),
        FilledButton(onPressed: _busy ? null : _save, child: Text(l.save)),
      ],
    );
  }
}
