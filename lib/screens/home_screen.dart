import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import '../models/folder.dart';
import '../services/file_service.dart';
import '../services/web_server.dart';
import 'folder_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FileService _fileService = FileService();
  List<Folder> _folders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    await _fileService.initialize();
    final folders = await _fileService.getFolders();
    setState(() {
      _folders = folders;
      _isLoading = false;
    });
  }

  Future<void> _createFolder() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Folder name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final folder = await _fileService.createFolder(result);
      if (folder != null) {
        setState(() {
          _folders.add(folder);
        });
      }
    }
  }

  Future<void> _deleteFolder(Folder folder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Folder'),
        content: Text('Are you sure you want to delete "${folder.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _fileService.deleteFolder(folder.path);
      if (success) {
        setState(() {
          _folders.remove(folder);
        });
      }
    }
  }

  void _showFolderMenu(Folder folder) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(folder.name),
        actions: [
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Delete'),
            onTap: () {
              Navigator.pop(context, 'delete');
            },
          ),
          ListTile(
            leading: const Icon(Icons.cancel),
            title: const Text('Cancel'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );

    if (result == 'delete') {
      await _deleteFolder(folder);
    }
  }

  @override
  Widget build(BuildContext context) {
    final webServer = Provider.of<WebServer>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manga Player'),
        actions: [
          Consumer<WebServer>(
            builder: (context, server, _) {
              return IconButton(
                icon: Icon(
                  Icons.cloud_upload,
                  color: server.isRunning ? Colors.green : Colors.grey,
                ),
                onPressed: () {
                  _showServerDialog(server);
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _folders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No folders yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: MasonryGridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    itemCount: _folders.length,
                    itemBuilder: (context, index) {
                      final folder = _folders[index];
                      return _buildFolderCard(folder);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createFolder,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFolderCard(Folder folder) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FolderScreen(folder: folder),
            ),
          ).then((_) {
            _loadFolders();
          });
        },
        onLongPress: () => _showFolderMenu(folder),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.folder,
                size: 48,
                color: Colors.blue[400],
              ),
              const SizedBox(height: 12),
              Text(
                folder.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${folder.imageCount} images',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showServerDialog(WebServer server) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Web Server'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${server.isRunning ? "Running" : "Stopped"}'),
            const SizedBox(height: 8),
            if (server.isRunning) ...[
              Text('URL: ${server.url}'),
              const SizedBox(height: 8),
              const Text('Open this URL in your browser on the same network'),
            ],
          ],
        ),
        actions: [
          if (server.isRunning)
            TextButton(
              onPressed: () async {
                await server.stop();
                Navigator.pop(context);
              },
              child: const Text('Stop'),
            )
          else
            TextButton(
              onPressed: () async {
                final success = await server.start(8080);
                Navigator.pop(context);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Server started')),
                  );
                }
              },
              child: const Text('Start'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
