import 'package:flutter/material.dart';

import '../glide_style.dart';
import '../labels.dart';

/// Search results shared by app search and contact search, so the two
/// screens look and behave the same (each still searches only its own kind).

/// The best match: a card like the favorites one (caps header, then the
/// content) with a larger row tinted with the accent. Enter opens it.
class BestMatchCard extends StatelessWidget {
  const BestMatchCard({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.onLongPress,
  });

  final Widget leading;
  final String title;
  final String? subtitle;

  /// Receives the row's context (for the app opening animation).
  final void Function(BuildContext) onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = GlideColors.of(context);
    return FlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CapsHeader(icon: Icons.bolt_rounded, label: context.l10n.bestMatch),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Material(
              color: c.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(cardRadius - 4),
              clipBehavior: Clip.antiAlias,
              child: Builder(
                builder: (rowContext) => InkWell(
                  onTap: () => onTap(rowContext),
                  onLongPress: onLongPress,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                    child: Row(
                      children: [
                        leading,
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (subtitle != null)
                                Text(
                                  subtitle!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: c.muted,
                                    fontSize: 13.5,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Enter opens this one.
                        Icon(
                          Icons.keyboard_return_rounded,
                          size: 18,
                          color: c.accent,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The other results, as plain rows in one card.
class OtherResultsCard extends StatelessWidget {
  const OtherResultsCard({
    super.key,
    required this.rows,
    this.dividerIndent = 66,
  });

  final List<Widget> rows;
  final double dividerIndent;

  @override
  Widget build(BuildContext context) {
    final c = GlideColors.of(context);
    return FlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CapsHeader(
            icon: Icons.search_rounded,
            label: context.l10n.otherResults,
          ),
          for (final (i, row) in rows.indexed) ...[
            if (i > 0)
              Divider(height: 1, indent: dividerIndent, color: c.hairline),
            row,
          ],
        ],
      ),
    );
  }
}

/// A small, unobtrusive "Search «text» on the web" line. With [enter] it
/// also shows that Enter runs it (when there are no results).
class WebSearchHint extends StatelessWidget {
  const WebSearchHint({
    super.key,
    required this.query,
    required this.onTap,
    this.enter = false,
  });

  final String query;
  final VoidCallback onTap;
  final bool enter;

  @override
  Widget build(BuildContext context) {
    final c = GlideColors.of(context);
    return Center(
      child: TextButton.icon(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: c.muted,
          visualDensity: VisualDensity.compact,
          textStyle: const TextStyle(fontSize: 13.5),
        ),
        icon: const Icon(Icons.travel_explore_rounded, size: 17),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                context.l10n.searchWeb(query),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (enter) ...[
              const SizedBox(width: 6),
              const Icon(Icons.keyboard_return_rounded, size: 15),
            ],
          ],
        ),
      ),
    );
  }
}
