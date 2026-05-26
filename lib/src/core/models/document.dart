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

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'folderId': folderId,
        'createdAt': createdAt.toIso8601String(),
        'isFavorite': isFavorite,
        'isEncrypted': isEncrypted,
        'ocrText': ocrText,
        'labels': labels,
        'pages': pages.map((p) => p.toJson()).toList(),
      };

  factory ChitraDocument.fromJson(Map<String, dynamic> j) => ChitraDocument(
        id: j['id'] as String,
        name: j['name'] as String,
        folderId: j['folderId'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        isFavorite: (j['isFavorite'] as bool?) ?? false,
        isEncrypted: (j['isEncrypted'] as bool?) ?? false,
        ocrText: j['ocrText'] as String?,
        labels: (j['labels'] as List<dynamic>?)?.cast<String>() ?? const [],
        pages: (j['pages'] as List<dynamic>)
            .map((p) => DocumentPage.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}
