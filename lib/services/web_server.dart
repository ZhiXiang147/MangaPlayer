import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'file_service.dart';
import '../models/app_settings.dart';

class WebServer extends ChangeNotifier {
  static final WebServer _instance = WebServer._internal();
  factory WebServer() => _instance;
  WebServer._internal();

  HttpServer? _server;
  bool _isRunning = false;
  int _port = 8080;
  String? _localIP;
  final FileService _fileService = FileService();

  bool get isRunning => _isRunning;
  int get port => _port;
  String? get localIP => _localIP;
  String get url => _isRunning ? 'http://$_localIP:$_port' : '';

  Future<bool> start(int port) async {
    if (_isRunning) {
      await stop();
    }

    try {
      _port = port;
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      _localIP = await _getLocalIP();
      _isRunning = true;
      notifyListeners();

      _server!.listen((HttpRequest request) async {
        await _handleRequest(request);
      });

      return true;
    } catch (e) {
      print('Failed to start server: $e');
      return false;
    }
  }

  Future<void> stop() async {
    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
    }
    _isRunning = false;
    _localIP = null;
    notifyListeners();
  }

  Future<String> _getLocalIP() async {
    try {
      final interfaces = await NetworkInterface.list();
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      print('Failed to get local IP: $e');
    }
    return '127.0.0.1';
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final path = request.uri.path;
    final method = request.method;

    try {
      if (path == '/' || path.isEmpty) {
      } else if (path == '/upload' && method == 'POST') {
      } else if (path == '/folders' && method == 'GET') {
      } else if (path == '/status' && method == 'GET') {
      } else {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
      }
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
      await request.response.close();
    }
  }

  Future<void> _handleHomePage(HttpRequest request) async {
    final folders = await _fileService.getFolders();
    
    String folderOptions = folders.map((f) {
      return '<option value="${f.path}">${f.name}</option>';
    }).join();

    String html = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Manga Player - Upload</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            text-align: center;
        }
        .form-group {
            margin-bottom: 20px;
        }
        label {
            display: block;
            margin-bottom: 5px;
            font-weight: bold;
            color: #555;
        }
        select, input[type="file"] {
            width: 100%;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 5px;
            font-size: 16px;
        }
        button {
            width: 100%;
            padding: 12px;
            background-color: #007AFF;
            color: white;
            border: none;
            border-radius: 5px;
            font-size: 16px;
            cursor: pointer;
        }
        button:hover {
            background-color: #0056b3;
        }
        button:disabled {
            background-color: #ccc;
            cursor: not-allowed;
        }
        .progress {
            margin-top: 20px;
            display: none;
        }
        .progress-bar {
            width: 100%;
            height: 20px;
            background-color: #e0e0e0;
            border-radius: 10px;
            overflow: hidden;
        }
        .progress-fill {
            height: 100%;
            background-color: #4CAF50;
            width: 0%;
            transition: width 0.3s;
        }
        .message {
            margin-top: 20px;
            padding: 10px;
            border-radius: 5px;
            display: none;
        }
        .success {
            background-color: #d4edda;
            color: #155724;
        }
        .error {
            background-color: #f8d7da;
            color: #721c24;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Upload Manga Images</h1>
        <div class="form-group">
            <label for="folder">Select Folder:</label>
            <select id="folder" name="folder" required>
                $folderOptions
            </select>
        </div>
        <div class="form-group">
            <label for="files">Select Images:</label>
            <input type="file" id="files" name="files" accept="image/*" multiple required>
        </div>
        <button id="uploadBtn" onclick="uploadFiles()">Upload</button>
        
        <div class="progress" id="progress">
            <div class="progress-bar">
                <div class="progress-fill" id="progressFill"></div>
            </div>
            <p id="progressText">0%</p>
        </div>
        
        <div class="message" id="message"></div>
    </div>

    <script>
        async function uploadFiles() {
            const folder = document.getElementById('folder').value;
            const files = document.getElementById('files').files;
            const progress = document.getElementById('progress');
            const progressFill = document.getElementById('progressFill');
            const progressText = document.getElementById('progressText');
            const message = document.getElementById('message');
            const uploadBtn = document.getElementById('uploadBtn');

            if (files.length === 0) {
                showMessage('Please select files to upload', 'error');
                return;
            }

            uploadBtn.disabled = true;
            progress.style.display = 'block';
            message.style.display = 'none';

            let uploaded = 0;
            for (let i = 0; i < files.length; i++) {
                const file = files[i];
                const formData = new FormData();
                formData.append('folder', folder);
                formData.append('file', file);

                try {
                    const response = await fetch('/upload', {
                        method: 'POST',
                        body: formData
                    });

                    if (response.ok) {
                        uploaded++;
                        const percent = Math.round((uploaded / files.length) * 100);
                        progressFill.style.width = percent + '%';
                        progressText.textContent = percent + '%';
                    } else {
                        throw new Error('Upload failed');
                    }
                } catch (error) {
                    showMessage('Failed to upload: ' + file.name, 'error');
                    uploadBtn.disabled = false;
                    return;
                }
            }

            showMessage('All files uploaded successfully!', 'success');
            uploadBtn.disabled = false;
            document.getElementById('files').value = '';
        }

        function showMessage(text, type) {
            const message = document.getElementById('message');
            message.textContent = text;
            message.className = 'message ' + type;
            message.style.display = 'block';
        }
    </script>
</body>
</html>
''';

    request.response
      ..headers.contentType = ContentType.html
      ..write(html);
    await request.response.close();
  }

  Future<void> _handleUpload(HttpRequest request) async {
    try {
      final contentType = request.headers.value('content-type');
      if (contentType == null || !contentType.contains('multipart/form-data')) {
        request.response.statusCode = HttpStatus.badRequest;
        await request.response.close();
        return;
      }

      final boundary = contentType.split('boundary=')[1];
      final bytes = await request.body.toList();
      final data = _parseMultipartFormData(bytes, boundary);

      final folderPath = data['folder'] as String?;
      final fileData = data['file'] as Map<String, dynamic>?;

      if (folderPath == null || fileData == null) {
        request.response.statusCode = HttpStatus.badRequest;
        await request.response.close();
        return;
      }

      final fileName = fileData['filename'] as String;
      final fileBytes = fileData['data'] as List<int>;

      final success = await _fileService.importImageBytes(fileBytes, folderPath, fileName);

      if (success) {
        request.response.statusCode = HttpStatus.ok;
      } else {
        request.response.statusCode = HttpStatus.internalServerError;
      }
      await request.response.close();
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
      await request.response.close();
    }
  }

  Future<void> _handleFolders(HttpRequest request) async {
    final folders = await _fileService.getFolders();
    final jsonResponse = jsonEncode({
      'folders': folders.map((f) => {
        'name': f.name,
        'path': f.path,
        'imageCount': f.imageCount,
      }).toList(),
    });

    request.response
      ..headers.contentType = ContentType.json
      ..write(jsonResponse);
    await request.response.close();
  }

  Future<void> _handleStatus(HttpRequest request) async {
    final jsonResponse = jsonEncode({
      'running': _isRunning,
      'port': _port,
      'ip': _localIP,
    });

    request.response
      ..headers.contentType = ContentType.json
      ..write(jsonResponse);
    await request.response.close();
  }

  Map<String, dynamic> _parseMultipartFormData(List<int> bytes, String boundary) {
    final boundaryBytes = '--$boundary'.codeUnits;
    final data = <String, dynamic>{};
    
    String? currentFieldName;
    String? currentFileName;
    List<int>? currentFileData;

    currentFieldName = null;
    currentFileName = null;
    currentFileData = null;

    String parseData(List<int> dataBytes) {
      try {
        return utf8.decode(dataBytes);
      } catch (e) {
        return '';
      }
    }

    return data;
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
