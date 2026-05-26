enum PageSizePreset { a4, letter, legal, idCard, passport, custom }

class DocumentPage {
  const DocumentPage({
    required this.id,
    required this.sourcePath,
    this.rotation = 0,
    this.notes,
    this.tags = const [],
  });

  final String id;
  final String sourcePath;
  final int rotation;
  final String? notes;
  final List<String> tags;

  DocumentPage copyWith({
    String? sourcePath,
    int? rotation,
    String? notes,
    List<String>? tags,
  }) {
    return DocumentPage(
      id: id,
      sourcePath: sourcePath ?? this.sourcePath,
      rotation: rotation ?? this.rotation,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourcePath': sourcePath,
        'rotation': rotation,
        'notes': notes,
        'tags': tags,
      };

  factory DocumentPage.fromJson(Map<String, dynamic> j) => DocumentPage(
        id: j['id'] as String,
        sourcePath: j['sourcePath'] as String,
        rotation: (j['rotation'] as int?) ?? 0,
        notes: j['notes'] as String?,
        tags: (j['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
      );
}
