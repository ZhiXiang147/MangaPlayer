class Folder {
  final String name;
  final String path;
  final int imageCount;
  final DateTime? lastModified;

  Folder({
    required this.name,
    required this.path,
    this.imageCount = 0,
    this.lastModified,
  });

  Folder copyWith({
    String? name,
    String? path,
    int? imageCount,
    DateTime? lastModified,
  }) {
    return Folder(
      name: name ?? this.name,
      path: path ?? this.path,
      imageCount: imageCount ?? this.imageCount,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}
