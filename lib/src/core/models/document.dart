import 'document_page.dart';

class ChitraDocument {
  const ChitraDocument({
    required this.id,
    required this.name,
    required this.folderId,
    required this.pages,
    required this.createdAt,
    this.isFavorite = false,
    this.isEncrypted = false,
    this.ocrText,
    this.labels = const [],
  });

  final String id;
  final String name;
  final String folderId;
  final List<DocumentPage> pages;
  final DateTime createdAt;
  final bool isFavorite;
  final bool isEncrypted;
  final String? ocrText;
  final List<String> labels;

  ChitraDocument copyWith({
    String? name,
    String? folderId,
    List<DocumentPage>? pages,
    bool? isFavorite,
    bool? isEncrypted,
    String? ocrText,
    List<String>? labels,
  }) {
    return ChitraDocument(
      id: id,
      name: name ?? this.name,
      folderId: folderId ?? this.folderId,
      pages: pages ?? this.pages,
      createdAt: createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      ocrText: ocrText ?? this.ocrText,
      labels: labels ?? this.labels,
    );
  }
}
