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
}
