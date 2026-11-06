import 'dart:async';

import 'package:flutter/material.dart';

import '../core/contact.dart';
import 'glide_style.dart';
import 'labels.dart';
import 'scope.dart';

/// Apre il pannello contatti salendo dal basso.
Future<void> showContactsPanel(BuildContext context) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, _, _) => const ContactsPage(),
      transitionsBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.12),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    ),
  );
}

/// Contatti: ricerca in alto, poi preferiti e più usati.
class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final _text = TextEditingController();
  String _query = '';
  List<Contact> _results = const [];
  Timer? _debounce;
  StreamSubscription<void>? _resumeSub;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_resumeSub == null) {
      final controller = AppScope.of(context).controller;
      controller.contacts.load();
      // Dopo il dialogo dei permessi si torna qui: si ricarica.
      _resumeSub = controller.bridge.resumed.listen(
        (_) => controller.contacts.load(),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _text.addListener(_onText);
  }

  void _onText() {
    final q = _text.text.trim();
    if (q == _query) return;
    setState(() => _query = q);
    _debounce?.cancel();
    if (q.isEmpty) {
      setState(() => _results = const []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 180), () async {
      final r = await AppScope.of(context).controller.contacts.search(q);
      if (mounted && q == _query) setState(() => _results = r);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _resumeSub?.cancel();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contacts = AppScope.of(context).controller.contacts;
    final c = GlideColors.of(context);
    final l = context.l10n;

    return Scaffold(
      backgroundColor: c.page,
      body: SafeArea(
        child: GestureDetector(
          // Swipe verso il basso per chiudere.
          onVerticalDragEnd: (d) {
            if ((d.primaryVelocity ?? 0) > 600) Navigator.of(context).pop();
          },
          child: ListenableBuilder(
            listenable: contacts,
            builder: (context, _) {
              final granted = contacts.permission ?? false;
              return ListView(
                padding: const EdgeInsets.all(cardGap),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  if (granted) ...[
                    PillSearchField(
                      controller: _text,
                      hint: l.contactsSearchHint,
                      autofocus: true,
                      onClose: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(height: cardGap),
                  ],
                  if (contacts.permission == false)
                    FlatCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CapsHeader(
                            icon: Icons.people_alt_rounded,
                            label: l.contactsTitle,
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 10, 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    l.contactsPermission,
                                    style: TextStyle(
                                      color: c.muted,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                FilledButton.tonal(
                                  onPressed: contacts.requestPermission,
                                  child: Text(l.allow),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_query.isNotEmpty)
                    _Results(contacts: _results)
                  else if (granted)
                    FlatCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CapsHeader(
                            icon: Icons.star_rounded,
                            label: l.contactsFavorites,
                          ),
                          if (contacts.favorites.isEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Text(
                                contacts.loading ? '' : l.contactsEmpty,
                                style: TextStyle(color: c.muted, height: 1.35),
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
                              child: Wrap(
                                children: [
                                  // Una riga sola: i primi 4.
                                  for (final contact in contacts.favorites.take(
                                    4,
                                  ))
                                    FractionallySizedBox(
                                      widthFactor: 0.25,
                                      child: _ContactTile(contact: contact),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.contacts});

  final List<Contact> contacts;

  @override
  Widget build(BuildContext context) {
    final c = GlideColors.of(context);
    if (contacts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            context.l10n.noContactsFound,
            style: TextStyle(color: c.muted),
          ),
        ),
      );
    }
    return FlatCard(
      child: Column(
        children: [
          for (final (i, contact) in contacts.indexed) ...[
            if (i > 0) Divider(height: 1, indent: 72, color: c.hairline),
            InkWell(
              onTap: () => _quickAction(context, contact),
              onLongPress: () => _showActions(context, contact),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    ContactAvatar(contact: contact, radius: 22),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contact.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (contact.number != null)
                            Text(
                              contact.number!,
                              style: TextStyle(color: c.muted, fontSize: 13),
                            ),
                        ],
                      ),
                    ),
                    if (contact.starred)
                      Icon(Icons.star_rounded, size: 18, color: c.accent),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(cardRadius),
    onTap: () => _quickAction(context, contact),
    onLongPress: () => _showActions(context, contact),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      child: Column(
        children: [
          ContactAvatar(contact: contact, radius: 27),
          const SizedBox(height: 6),
          Text(
            contact.name.split(' ').first,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textScaler: MediaQuery.textScalerOf(context)
                .clamp(maxScaleFactor: maxLabelScale),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    ),
  );
}

/// Foto del contatto o iniziali su un colore tonale stabile per nome.
class ContactAvatar extends StatelessWidget {
  const ContactAvatar({super.key, required this.contact, this.radius = 24});

  final Contact contact;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = [
      (scheme.primaryContainer, scheme.onPrimaryContainer),
      (scheme.secondaryContainer, scheme.onSecondaryContainer),
      (scheme.tertiaryContainer, scheme.onTertiaryContainer),
    ];
    final (bg, fg) = palette[contact.name.hashCode.abs() % palette.length];
    if (contact.photo != null) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: MemoryImage(contact.photo!),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      child: Text(
        contact.initials,
        textScaler: TextScaler.noScaling,
        style: TextStyle(
          color: fg,
          fontSize: radius * 0.7,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Tocco su un contatto: subito il compositore con il suo numero (senza
/// avviare la chiamata), o la scheda se non ha un numero. Poi il pannello
/// si chiude.
Future<void> _quickAction(BuildContext context, Contact contact) async {
  final contacts = AppScope.of(context).controller.contacts;
  final navigator = Navigator.of(context);
  FocusManager.instance.primaryFocus?.unfocus();
  contact.number != null
      ? await contacts.dial(contact)
      : await contacts.open(contact);
  Future<void>.delayed(const Duration(milliseconds: 350), () {
    if (navigator.canPop()) navigator.pop();
  });
}

/// Pressione lunga: chiama, messaggio, scheda.
Future<void> _showActions(BuildContext context, Contact contact) {
  final contacts = AppScope.of(context).controller.contacts;
  final l = context.l10n;
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (sheetContext) {
      void run(Future<void> Function(Contact) action) {
        final navigator = Navigator.of(context);
        Navigator.pop(sheetContext);
        action(contact);
        // Chiude anche il pannello: tornando al launcher si ritrova la
        // schermata di partenza.
        Future<void>.delayed(const Duration(milliseconds: 350), () {
          if (navigator.canPop()) navigator.pop();
        });
      }

      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: ContactAvatar(contact: contact, radius: 22),
              title: Text(
                contact.name,
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              subtitle: contact.number == null ? null : Text(contact.number!),
            ),
            const Divider(indent: 24, endIndent: 24),
            if (contact.number != null) ...[
              ListTile(
                leading: const Icon(Icons.call_rounded),
                title: Text(l.call),
                onTap: () => run(contacts.dial),
              ),
              ListTile(
                leading: const Icon(Icons.sms_rounded),
                title: Text(l.message),
                onTap: () => run(contacts.sms),
              ),
            ],
            ListTile(
              leading: const Icon(Icons.person_rounded),
              title: Text(l.openContact),
              onTap: () => run(contacts.open),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
