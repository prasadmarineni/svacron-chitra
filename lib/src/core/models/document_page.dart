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

  DocumentPage copyWith({int? rotation, String? notes, List<String>? tags}) {
    return DocumentPage(
      id: id,
      sourcePath: sourcePath,
      rotation: rotation ?? this.rotation,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
    );
  }
}
