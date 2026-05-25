import 'package:flutter/material.dart';

import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/ocr/presentation/ocr_page.dart';
import '../features/organize/presentation/organize_page.dart';
import '../features/pdf_tools/presentation/pdf_tools_page.dart';
import '../features/scanner/presentation/scanner_page.dart';
import '../features/settings/presentation/settings_page.dart';
import '../theme/app_theme.dart';

class ChitraApp extends StatelessWidget {
  const ChitraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Svacron Chitra: Document Scanner, PDF Viewer, Merge & Split',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  final List<Widget> _pages = const [
    DashboardPage(),
    ScannerPage(),
    PdfToolsPage(),
    OrganizePage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Svacron Chitra'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch<void>(
                context: context,
                delegate: _DocSearchDelegate(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.text_snippet_outlined),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute<void>(builder: (_) => const OcrPage()));
            },
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.document_scanner_outlined),
            selectedIcon: Icon(Icons.document_scanner),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.picture_as_pdf_outlined),
            selectedIcon: Icon(Icons.picture_as_pdf),
            label: 'PDF',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Organize',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _DocSearchDelegate extends SearchDelegate<void> {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _SearchPlaceholder(query: query);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _SearchPlaceholder(query: query);
  }
}

class _SearchPlaceholder extends StatelessWidget {
  const _SearchPlaceholder({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          query.isEmpty
              ? 'Start typing to search documents'
              : 'No local matches for "$query" yet',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'Search by name, folder, tag, OCR text, or file type will be available as data is added.',
        ),
      ],
    );
  }
}
