import 'package:flutter/material.dart';

import '../../../core/state/chitra_session.dart';
import 'feature_catalog.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = ChitraSession.instance;
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final allDocs = session.documents;
        final totalPages =
            allDocs.fold<int>(0, (sum, doc) => sum + doc.pages.length);
        final recentDocs = session.recentDocuments.take(5).toList();
        final favoritesCount = session.favoriteDocuments.length;
        final trashCount = session.trashedDocuments.length;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Welcome card
            _WelcomeCard(),
            const SizedBox(height: 16),

            // Statistics grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
              children: [
                _StatCard(
                  icon: Icons.description_outlined,
                  label: 'Documents',
                  value: '${allDocs.length}',
                  color: Colors.blue,
                ),
                _StatCard(
                  icon: Icons.description,
                  label: 'Total Pages',
                  value: '$totalPages',
                  color: Colors.orange,
                ),
                _StatCard(
                  icon: Icons.star_outlined,
                  label: 'Favorites',
                  value: '$favoritesCount',
                  color: Colors.amber,
                ),
                _StatCard(
                  icon: Icons.delete_outlined,
                  label: 'Trash',
                  value: '$trashCount',
                  color: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Quick actions section
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: const [
                _QuickActionChip(
                  icon: Icons.document_scanner,
                  label: 'Scan Document',
                  targetTab: 1,
                ),
                _QuickActionChip(
                  icon: Icons.picture_as_pdf_outlined,
                  label: 'PDF Tools',
                  targetTab: 2,
                ),
                _QuickActionChip(
                  icon: Icons.folder_outlined,
                  label: 'Organize',
                  targetTab: 3,
                ),
                _QuickActionChip(
                  icon: Icons.text_snippet_outlined,
                  label: 'Extract Text',
                  targetTab: 4,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Recent documents section
            if (recentDocs.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Documents',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to Organize page (tab 3)
                      // This will be handled by parent widget
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _RecentDocumentsList(docs: recentDocs),
              const SizedBox(height: 20),
            ],

            // Feature catalog
            Text(
              'Features',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ...featureCatalog.map(
              (group) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  title: Text(group.title),
                  children: [
                    for (final item in group.items)
                      ListTile(
                        leading: const Icon(Icons.check_circle_outline,
                            size: 18),
                        title: Text(item),
                        dense: true,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Welcome card
// ══════════════════════════════════════════════════════════════════════════════
class _WelcomeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to Svacron Chitra',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Your offline-first document scanner and PDF viewer. Start by scanning a document or importing images.',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Statistics card
// ══════════════════════════════════════════════════════════════════════════════
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Quick action chip
// ══════════════════════════════════════════════════════════════════════════════
class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.targetTab,
  });

  final IconData icon;
  final String label;
  final int targetTab;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: () {
        // This will be handled by parent widget
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Recent documents list
// ══════════════════════════════════════════════════════════════════════════════
class _RecentDocumentsList extends StatelessWidget {
  const _RecentDocumentsList({required this.docs});

  final List<dynamic> docs;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: docs.length,
      itemBuilder: (ctx, i) {
        final doc = docs[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              Icons.description_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              doc.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
            subtitle: Text(
              '${doc.pages.length} page(s)',
              style: const TextStyle(fontSize: 11),
            ),
            trailing: const Icon(Icons.chevron_right, size: 18),
            dense: true,
            onTap: () {
              // Navigate to Organize page to view document
            },
          ),
        );
      },
    );
  }
}
