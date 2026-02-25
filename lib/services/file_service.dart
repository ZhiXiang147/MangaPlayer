import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/app_settings.dart';
import '../models/folder.dart';
import '../models/manga_image.dart';

class FileService {
  static final FileService _instance = FileService._internal();
  factory FileService() => _instance;
  FileService._internal();

  Directory? _appDocumentsDir;
  Directory? _foldersDir;

  static const List<String> supportedExtensions = [
    '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.heic',
    '.JPG', '.JPEG', '.PNG', '.GIF', '.BMP', '.WEBP', '.HEIC',
  ];

  Future<void> initialize() async {
    _appDocumentsDir = await getApplicationDocumentsDirectory();
    _foldersDir = Directory('${_appDocumentsDir!.path}/folders');
    
    if (!await _foldersDir!.exists()) {
      await _foldersDir!.create(recursive: true);
    }
  }

  Future<Directory> get foldersDir async {
    if (_foldersDir == null) {
      await initialize();
    }
    return _foldersDir!;
  }

  Future<Directory> get appDocumentsDir async {
    if (_appDocumentsDir == null) {
      await initialize();
    }
    return _appDocumentsDir!;
  }

  Future<List<Folder>> getFolders() async {
    final dir = await foldersDir;
    final entities = await dir.list().toList();
    
    List<Folder> folders = [];
    for (var entity in entities) {
      if (entity is Directory) {
        final images = await _getImagesInFolder(entity);
        folders.add(Folder(
          name: entity.uri.pathSegments.last,
          path: entity.path,
          imageCount: images.length,
          lastModified: entity.statSync().modified,
        ));
      }
    }
    
    folders.sort((a, b) => (a.lastModified ?? DateTime.now()).compareTo(b.lastModified ?? DateTime.now()));
    return folders;
  }

  Future<List<MangaImage>> getImages(String folderPath) async {
    final folder = Directory(folderPath);
    return _getImagesInFolder(folder);
  }

  Future<List<MangaImage>> _getImagesInFolder(Directory folder) async {
    final entities = await folder.list().toList();
    
    List<MangaImage> images = [];
    for (var entity in entities) {
      if (entity is File) {
        final ext = entity.path.substring(entity.path.lastIndexOf('.'));
        if (supportedExtensions.contains(ext)) {
          images.add(MangaImage(
            name: entity.uri.pathSegments.last,
            path: entity.path,
            size: entity.lengthSync(),
            lastModified: entity.lastModifiedSync(),
          ));
        }
      }
    }
    
    images.sort((a, b) => a.name.compareTo(b.name));
    return images;
  }

  Future<Folder?> createFolder(String name) async {
    final dir = await foldersDir;
    final newFolder = Directory('${dir.path}/$name');
    
    if (await newFolder.exists()) {
      return null;
    }
    
    await newFolder.create(recursive: true);
    return Folder(
      name: name,
      path: newFolder.path,
      imageCount: 0,
      lastModified: newFolder.statSync().modified,
    );
  }

  Future<bool> deleteFolder(String path) async {
    try {
      final folder = Directory(path);
      if (await folder.exists()) {
        await folder.delete(recursive: true);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteImage(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> importImage(String sourcePath, String folderPath, String? newName) async {
    try {
      final sourceFile = File(sourcePath);
      final folder = Directory(folderPath);
      
      if (!await sourceFile.exists() || !await folder.exists()) {
        return false;
      }
      
      final destPath = newName != null 
          ? '${folder.path}/$newName'
          : '${folder.path}/${sourceFile.uri.pathSegments.last}';
      
      final destFile = File(destPath);
      await sourceFile.copy(destPath);
      return true;
;
    } catch (e) {
      return false;
    }
  }

  Future<bool> importImageBytes(List<int> bytes, String folderPath, String fileName) async {
    try {
      final folder = Directory(folderPath);
      
      if (!await folder.exists()) {
        return false;
      }
      
      final destPath = '${folder.path}/$fileName';
      final destFile = File(destPath);
      await destFile.writeAsBytes(bytes);
      return true;
    } catch (e) {
    } catch (e) {
      return false;
    }
  }

  Future<AppSettings> loadSettings() async {
    try {
      final dir = await appDocumentsDir;
      final settingsFile = File('${dir.path}/settings.json');
      
      if (await settingsFile.exists()) {
        final content = await settingsFile.readAsString();
        return AppSettings.fromJsonString(content);
      }
      return AppSettings();
    } catch (e) {
      return AppSettings();
    }
  }

  Future<bool> saveSettings(AppSettings settings) async {
    try {
      final dir = await appDocumentsDir;
      final settingsFile = File('${dir.path}/settings.json');
');
      return true;
    } catch (e) {
      return false;
    }
  }
}
