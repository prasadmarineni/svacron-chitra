import '../models/document.dart';
import '../models/document_page.dart';
import '../models/folder.dart';

abstract class DocumentRepository {
  Future<List<ChitraFolder>> getFolders();
  Future<List<ChitraDocument>> getDocuments();
  Future<void> saveDocument(ChitraDocument document);
}

class InMemoryDocumentRepository implements DocumentRepository {
  InMemoryDocumentRepository()
    : _folders = const [
        ChitraFolder(id: 'f1', name: 'Bills'),
        ChitraFolder(id: 'f2', name: 'Notes'),
        ChitraFolder(id: 'f3', name: 'IDs', isLocked: true),
      ],
      _documents = [
        ChitraDocument(
          id: 'd1',
          name: 'Receipt_2026_05_25.pdf',
          folderId: 'f1',
          pages: const [
            DocumentPage(id: 'p1', sourcePath: 'local://receipt-1.jpg'),
          ],
          createdAt: DateTime(2026, 5, 25),
          labels: const ['receipt', 'tax'],
        ),
      ];

  final List<ChitraFolder> _folders;
  final List<ChitraDocument> _documents;

  @override
  Future<List<ChitraFolder>> getFolders() async => _folders;

  @override
  Future<List<ChitraDocument>> getDocuments() async => _documents;

  @override
  Future<void> saveDocument(ChitraDocument document) async {
    _documents.removeWhere((element) => element.id == document.id);
    _documents.add(document);
  }
}
