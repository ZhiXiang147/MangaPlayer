import 'dart:io';

class MangaImage {
  final String name;
  final String path;
  final int size;
  final DateTime? lastModified;

  MangaImage({
    required this.name,
    required this.path,
    this.size = 0,
    this.lastModified,
  });

  MangaImage fromFile(File file) {
    return MangaImage(
      name: file.uri.pathSegments.last,
      path: file.path,
      size: file.lengthSync(),
      lastModified: file.lastModifiedSync(),
    );
  }

  MangaImage copyWith({
    String? name,
    String? path,
    int? size,
    DateTime? lastModified,
  }) {
    return MangaImage(
      name: name ?? this.name,
      path: path ?? this.path,
      size: size ?? this.size,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}
