class ChitraFolder {
  const ChitraFolder({
    required this.id,
    required this.name,
    this.isLocked = false,
    this.isHidden = false,
  });

  final String id;
  final String name;
  final bool isLocked;
  final bool isHidden;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isLocked': isLocked,
        'isHidden': isHidden,
      };

  factory ChitraFolder.fromJson(Map<String, dynamic> j) => ChitraFolder(
        id: j['id'] as String,
        name: j['name'] as String,
        isLocked: (j['isLocked'] as bool?) ?? false,
        isHidden: (j['isHidden'] as bool?) ?? false,
      );
}
