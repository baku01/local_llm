import 'package:flutter/material.dart';
import 'dart:io';

class McpToolsWidget extends StatefulWidget {
  const McpToolsWidget({super.key});

  @override
  State<McpToolsWidget> createState() => _McpToolsWidgetState();
}

class _McpToolsWidgetState extends State<McpToolsWidget> {
  final TextEditingController _pathController = TextEditingController();
  final TextEditingController _fileContentController = TextEditingController();
  final String _currentDirectory = Directory.current.path;
  String _output = '';

  void _createFolder() async {
    final path = _pathController.text.trim();
    if (path.isEmpty) {
      setState(() {
        _output = 'Error: Folder name cannot be empty.';
      });
      return;
    }

    final newDirectory = Directory('$_currentDirectory/$path');
    if (await newDirectory.exists()) {
      setState(() {
        _output = 'Error: Folder already exists.';
      });
    } else {
      await newDirectory.create();
      setState(() {
        _output = 'Folder created: ${newDirectory.path}';
      });
    }
  }

  void _createFile() async {
    final path = _pathController.text.trim();
    final content = _fileContentController.text;
    if (path.isEmpty) {
      setState(() {
        _output = 'Error: File name cannot be empty.';
      });
      return;
    }

    final newFile = File('$_currentDirectory/$path');
    if (await newFile.exists()) {
      setState(() {
        _output = 'Error: File already exists.';
      });
    } else {
      await newFile.writeAsString(content);
      setState(() {
        _output = 'File created: ${newFile.path}';
      });
    }
  }

  void _listDirectory() async {
    final directory = Directory(_currentDirectory);
    if (await directory.exists()) {
      final contents = directory.listSync();
      setState(() {
        _output =
            'Contents of $_currentDirectory:\n${contents.map((e) => e.path).join('\n')}';
      });
    } else {
      setState(() {
        _output = 'Error: Directory does not exist.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MCP Tools')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _pathController,
              decoration: const InputDecoration(
                labelText: 'File/Folder Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _fileContentController,
              decoration: const InputDecoration(
                labelText: 'File Content (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _createFolder,
                  child: const Text('Create Folder'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _createFile,
                  child: const Text('Create File'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _listDirectory,
                  child: const Text('List Directory'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Current Directory: $_currentDirectory',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_output, style: const TextStyle(color: Colors.blue)),
          ],
        ),
      ),
    );
  }
}
