import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oman_agri/features/crops/data/knowledge_repository.dart';
import 'package:oman_agri/features/crops/data/models.dart';
import 'package:oman_agri/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// Icon button that opens a bottom sheet describing where a fact came from.
class SourceButton extends ConsumerWidget {
  const SourceButton({super.key, required this.sourceId, this.page});

  final String sourceId;
  final String? page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return IconButton(
      tooltip: l10n.source,
      icon: const Icon(Icons.menu_book_outlined),
      onPressed: () {
        final source = ref.read(knowledgeProvider).asData?.value.sources[sourceId];
        showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          isScrollControlled: true,
          builder: (_) => _SourceSheet(source: source, sourceId: sourceId, page: page),
        );
      },
    );
  }
}

class _SourceSheet extends StatelessWidget {
  const _SourceSheet({required this.source, required this.sourceId, this.page});

  final Source? source;
  final String sourceId;
  final String? page;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final s = source;
    final url = s?.url;
    Widget line(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text.rich(TextSpan(children: [
            TextSpan(
                text: '$label: ',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ])),
        );
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.source, style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(s?.title ?? sourceId, style: theme.textTheme.titleMedium),
            ),
            const SizedBox(height: 8),
            if (s != null && s.publisher.isNotEmpty)
              line(l10n.sourcePublisher, s.publisher),
            if (s?.year != null) line(l10n.sourceYear, '${s!.year}'),
            if (page != null && page!.isNotEmpty) line(l10n.sourcePage, page!),
            if (url != null && url.isNotEmpty)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.open_in_new),
                title: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(url,
                      style: TextStyle(
                          color: theme.colorScheme.primary,
                          decoration: TextDecoration.underline)),
                ),
                subtitle: Text(l10n.openLink),
                onTap: () {
                  final uri = Uri.tryParse(url);
                  if (uri != null) {
                    launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
