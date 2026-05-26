import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/models/document.dart';
import '../../../core/models/folder.dart';
import '../../../core/state/chitra_session.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = ChitraSession.instance;
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final allDocs = session.documents;
        final recentDocs = session.recentDocuments.take(5).toList();
        final folders = session.folders;
        final hasContent = allDocs.isNotEmpty;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // ── Recent (always on top) ─────────────────────────────────────
            _SectionHeader(
              title: 'Recent',
              trailing: recentDocs.isNotEmpty
                  ? TextButton(
                      onPressed: () {},
                      child: const Text('View All'),
                    )
                  : null,
            ),
            const SizedBox(height: 6),
            if (recentDocs.isEmpty)
              _EmptyCard(
                icon: Icons.access_time,
                message: 'No recent documents yet.\nScan or import to get started.',
              )
            else
              ...recentDocs.map((doc) => _RecentDocRow(doc: doc, session: session)),
            const SizedBox(height: 24),

            // ── Folders ────────────────────────────────────────────────────
            _SectionHeader(title: 'Folders'),
            const SizedBox(height: 6),
            if (!hasContent)
              _EmptyCard(
                icon: Icons.folder_open_outlined,
                message: 'No folders or documents yet.',
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                ),
                itemCount: folders.length,
                itemBuilder: (ctx, i) => _FolderCard(
                  folder: folders[i],
                  docCount: session.documentsInFolder(folders[i].id).length,
                ),
              ),

            // end of content
          ],
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Section header
// ══════════════════════════════════════════════════════════════════════════════
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Empty card (shown when nothing to display)
// ══════════════════════════════════════════════════════════════════════════════
class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Recent document row
// ══════════════════════════════════════════════════════════════════════════════
class _RecentDocRow extends StatelessWidget {
  const _RecentDocRow({required this.doc, required this.session});

  final ChitraDocument doc;
  final ChitraSession session;

  String get _folderName {
    try {
      return session.folders.firstWhere((f) => f.id == doc.folderId).name;
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstPath =
        doc.pages.isNotEmpty ? doc.pages.first.sourcePath : null;
    final hasFile = firstPath != null && File(firstPath).existsSync();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: hasFile
              ? Image.file(
                  File(firstPath),
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: 44,
                  height: 44,
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  child: Icon(
                    Icons.insert_drive_file_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
        ),
        title: Text(
          doc.name,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${doc.pages.length} page(s)${_folderName.isNotEmpty ? '  ·  $_folderName' : ''}',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: doc.isFavorite
            ? const Icon(Icons.star, color: Colors.amber, size: 18)
            : const Icon(Icons.chevron_right, size: 18),
        onTap: () {},
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Folder card
// ══════════════════════════════════════════════════════════════════════════════
class _FolderCard extends StatelessWidget {
  const _FolderCard({required this.folder, required this.docCount});

  final ChitraFolder folder;
  final int docCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    folder.isLocked ? Icons.lock : Icons.folder,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$docCount',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                folder.name,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                docCount == 1 ? '1 document' : '$docCount documents',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
