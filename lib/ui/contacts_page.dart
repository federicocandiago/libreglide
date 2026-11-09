import 'dart:async';

import 'package:flutter/material.dart';

import '../core/contact.dart';
import 'gestures.dart';
import 'glide_style.dart';
import 'labels.dart';
import 'scope.dart';
import 'widgets/search_results.dart';
import 'widgets/glass_photo.dart';
import 'widgets/swipe_to_close.dart';

/// Opens the contacts panel. It slides in following the swipe that
/// [openedBy] (from the bottom when opened otherwise) and closes with the
/// opposite swipe.
Future<void> showContactsPanel(
  BuildContext context, {
  SwipeDirection? openedBy,
}) {
  final enter = openedBy ?? SwipeDirection.up;
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, _, _) => ContactsPage(closeSwipe: enter.opposite),
      transitionsBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween(
            begin: Offset(0, enter == SwipeDirection.up ? 0.12 : -0.12),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    ),
  );
}

/// Contacts: search at the top, then favorites and most used.
class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key, this.closeSwipe = SwipeDirection.down});

  /// The swipe that closes the panel and goes back to Home.
  final SwipeDirection closeSwipe;

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  String _query = '';
  List<Contact> _results = const [];

  /// The text [_results] belong to: Enter acts only on fresh results.
  String? _resultsFor;
  Timer? _debounce;
  StreamSubscription<void>? _resumeSub;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_resumeSub == null) {
      final controller = AppScope.of(context).controller;
      controller.contacts.load();
      // After the permission dialog the user returns here: reload.
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
      setState(() {
        _results = const [];
        _resultsFor = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 180), () => _search(q));
  }

  Future<List<Contact>> _search(String q) async {
    final r = await AppScope.of(context).controller.contacts.search(q);
    if (mounted && q == _query) {
      setState(() {
        _results = r;
        _resultsFor = q;
      });
    }
    return r;
  }

  /// Enter: the best match (searching right away if the results for this
  /// text haven't arrived yet).
  Future<void> _submit() async {
    final q = _query;
    if (q.isEmpty) return;
    _debounce?.cancel();
    final r = _resultsFor == q ? _results : await _search(q);
    if (!mounted || q != _query || r.isEmpty) return;
    await _quickAction(context, r.first);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _resumeSub?.cancel();
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contacts = AppScope.of(context).controller.contacts;
    final c = GlideColors.of(context);
    final l = context.l10n;

    // The blurred Unsplash photo stays behind the page, as on Home: no
    // fade to the phone's wallpaper.
    return GlassPhoto(
      child: Scaffold(
        backgroundColor: c.page,
        body: SafeArea(
          child: SwipeToClose(
            direction: widget.closeSwipe,
            scroll: _scroll,
            onClose: () => Navigator.of(context).maybePop(),
            child: ListenableBuilder(
              listenable: contacts,
              builder: (context, _) {
                final granted = contacts.permission ?? false;
                return ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.all(cardGap),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    if (granted) ...[
                      PillSearchField(
                        controller: _text,
                        hint: l.contactsSearchHint,
                        autofocus: true,
                        onSubmitted: _submit,
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
                      _Results(
                        contacts: _results,
                        // No "not found" while the first results are on their
                        // way.
                        settled: _resultsFor == _query,
                      )
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
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  16,
                                ),
                                child: Text(
                                  contacts.loading ? '' : l.contactsEmpty,
                                  style: TextStyle(
                                    color: c.muted,
                                    height: 1.35,
                                  ),
                                ),
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
                                child: Wrap(
                                  children: [
                                    // A single row: the first 4.
                                    for (final contact
                                        in contacts.favorites.take(4))
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
      ),
    );
  }
}

/// Results: the best match (Enter calls it), then the others.
class _Results extends StatelessWidget {
  const _Results({required this.contacts, required this.settled});

  final List<Contact> contacts;
  final bool settled;

  @override
  Widget build(BuildContext context) {
    final c = GlideColors.of(context);
    if (contacts.isEmpty) {
      if (!settled) return const SizedBox();
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
    final best = contacts.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BestMatchCard(
          leading: ContactAvatar(contact: best, radius: 26),
          title: best.name,
          subtitle: best.number,
          onTap: (_) => _quickAction(context, best),
          onLongPress: () => _showActions(context, best),
        ),
        if (contacts.length > 1) ...[
          const SizedBox(height: cardGap),
          OtherResultsCard(
            dividerIndent: 72,
            rows: [
              for (final contact in contacts.skip(1))
                _ContactRow(contact: contact),
            ],
          ),
        ],
      ],
    );
  }
}

/// A contact in the results: avatar, name, number, star.
class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context) {
    final c = GlideColors.of(context);
    return InkWell(
      onTap: () => _quickAction(context, contact),
      onLongPress: () => _showActions(context, contact),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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

/// Contact photo, or initials on a tonal color that is stable per name. The
/// photo is loaded once per contact and cached (initials until it arrives).
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
    final initials = CircleAvatar(
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
    if (!contact.hasPhoto) return initials;
    return FutureBuilder<ImageProvider?>(
      future: AppScope.of(context).controller.contacts.photo(contact),
      builder: (context, snap) {
        final image = snap.data;
        if (image == null) return initials;
        return CircleAvatar(radius: radius, backgroundImage: image);
      },
    );
  }
}

/// Tap on a contact: opens the dialer with their number right away (without
/// starting the call), or the contact card if there is no number. Then the
/// panel closes.
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

/// Long press: call, message, contact card.
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
        // Close the panel too: returning to the launcher shows the starting
        // screen.
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
