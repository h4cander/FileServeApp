import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:path_provider/path_provider.dart';
import 'package:file_serve_app/services/logger_service.dart';
import 'package:network_info_plus/network_info_plus.dart';

class FileServer {
  HttpServer? _server;
  static const int _port = 8080;

  Future<String> start(LoggerService logger) async {
    if (_server != null) {
      throw Exception('Server is already running');
    }

    final handler = const Pipeline()
        .addMiddleware(_corsMiddleware())
        .addMiddleware(logRequests())
        .addHandler((Request request) => _handleRequest(request, logger));

    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, _port);
    
    // Get local IP address
    final info = NetworkInfo();
    final wifiIP = await info.getWifiIP();
    final ip = wifiIP ?? 'localhost';
    
    return 'http://$ip:$_port';
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  Middleware _corsMiddleware() {
    return (Handler handler) {
      return (Request request) async {
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: _corsHeaders);
        }

        final response = await handler(request);
        return response.change(headers: _corsHeaders);
      };
    };
  }

  Map<String, String> get _corsHeaders => {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, DELETE, PUT, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      };

  Future<Response> _handleRequest(Request request, LoggerService logger) async {
    final path = request.url.path;
    final clientIp = request.headers['x-forwarded-for'] ?? 
                     request.context['shelf.io.connection_info']?.toString() ?? 
                     'unknown';

    try {
      // Serve static web interface
      if (path == '' || path == '/') {
        return _serveIndexHtml();
      }

      // API endpoints
      if (path.startsWith('api/')) {
        return await _handleApiRequest(request, logger, clientIp);
      }

      return Response.notFound('Not found');
    } catch (e) {
      await logger.log(clientIp, 'Error: $e');
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  }

  Future<Response> _handleApiRequest(Request request, LoggerService logger, String clientIp) async {
    final path = request.url.path.substring(4); // Remove 'api/' prefix
    final method = request.method;

    if (path == 'list') {
      return await _handleList(request, logger, clientIp);
    } else if (path == 'get') {
      return await _handleGet(request, logger, clientIp);
    } else if (path == 'upload' && method == 'POST') {
      return await _handleUpload(request, logger, clientIp);
    } else if (path == 'delete' && method == 'DELETE') {
      return await _handleDelete(request, logger, clientIp);
    } else if (path == 'rename' && method == 'PUT') {
      return await _handleRename(request, logger, clientIp);
    } else if (path == 'mkdir' && method == 'POST') {
      return await _handleMkdir(request, logger, clientIp);
    }

    return Response.notFound('API endpoint not found');
  }

  Future<Response> _handleList(Request request, LoggerService logger, String clientIp) async {
    final queryParams = request.url.queryParameters;
    final requestPath = queryParams['path'] ?? '';
    
    final baseDir = await _getStorageDirectory();
    final targetDir = Directory('${baseDir.path}/$requestPath');

    if (!await targetDir.exists()) {
      return Response.notFound(jsonEncode({'error': 'Directory not found'}));
    }

    final entries = await targetDir.list().toList();
    final files = <Map<String, dynamic>>[];

    for (var entry in entries) {
      final stat = await entry.stat();
      final isDirectory = entry is Directory;
      final name = entry.path.split('/').last;

      files.add({
        'name': name,
        'path': requestPath.isEmpty ? name : '$requestPath/$name',
        'isDirectory': isDirectory,
        'size': isDirectory ? 0 : stat.size,
        'modified': stat.modified.toIso8601String(),
      });
    }

    await logger.log(clientIp, 'LIST: $requestPath');
    
    return Response.ok(
      jsonEncode({'files': files, 'currentPath': requestPath}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> _handleGet(Request request, LoggerService logger, String clientIp) async {
    final queryParams = request.url.queryParameters;
    final filePath = queryParams['path'];

    if (filePath == null) {
      return Response.badRequest(body: jsonEncode({'error': 'Path parameter required'}));
    }

    final baseDir = await _getStorageDirectory();
    final file = File('${baseDir.path}/$filePath');

    if (!await file.exists()) {
      return Response.notFound(jsonEncode({'error': 'File not found'}));
    }

    await logger.log(clientIp, 'GET: $filePath');

    final bytes = await file.readAsBytes();
    final fileName = filePath.split('/').last;
    
    return Response.ok(
      bytes,
      headers: {
        'Content-Type': 'application/octet-stream',
        'Content-Disposition': 'attachment; filename="$fileName"',
      },
    );
  }

  Future<Response> _handleUpload(Request request, LoggerService logger, String clientIp) async {
    try {
      // Read raw bytes from request
      final bytes = await request.read().expand((chunk) => chunk).toList();
      
      // Get content type and boundary
      final contentType = request.headers['content-type'] ?? '';
      if (!contentType.contains('multipart/form-data')) {
        return Response.badRequest(body: jsonEncode({'error': 'Invalid content type'}));
      }
      
      final boundaryMatch = RegExp(r'boundary=([^;]+)').firstMatch(contentType);
      if (boundaryMatch == null) {
        return Response.badRequest(body: jsonEncode({'error': 'No boundary found'}));
      }
      
      final boundary = '--${boundaryMatch.group(1)}';
      final boundaryBytes = utf8.encode(boundary);
      
      // Parse multipart data
      String? fileName;
      String? targetPath;
      List<int>? fileBytes;
      
      // Convert to string to find headers (allowMalformed is used because binary file data
      // may be present in the multipart body, which is not valid UTF-8. We only need the
      // headers to be readable, and we extract binary data directly from bytes array)
      final content = utf8.decode(bytes, allowMalformed: true);
      final parts = content.split(boundary);
      
      // Note: This parsing method is O(n*m) where n is content size and m is number of parts.
      // For very large files, consider using a streaming multipart parser library.
      for (var part in parts) {
        // Check if this part contains a file
        if (part.contains('filename=')) {
          // Extract filename
          final nameMatch = RegExp(r'filename="([^"]+)"').firstMatch(part);
          if (nameMatch != null) {
            fileName = nameMatch.group(1);
          }
          
          // Find where actual file data starts (after headers)
          final headerEndIndex = part.indexOf('\r\n\r\n');
          if (headerEndIndex != -1) {
            // Get the byte offset in original bytes array
            final partStartInBytes = content.indexOf(part);
            final dataStartInPart = headerEndIndex + 4;
            final dataStartInBytes = partStartInBytes + dataStartInPart;
            
            // Find where this part ends (look for next boundary or end)
            int dataEndInBytes = dataStartInBytes;
            for (int i = dataStartInBytes; i < bytes.length - boundaryBytes.length; i++) {
              bool isBoundary = true;
              for (int j = 0; j < boundaryBytes.length; j++) {
                if (i + j >= bytes.length || bytes[i + j] != boundaryBytes[j]) {
                  isBoundary = false;
                  break;
                }
              }
              if (isBoundary) {
                dataEndInBytes = i;
                break;
              }
            }
            
            if (dataEndInBytes > dataStartInBytes) {
              // Remove trailing \r\n before boundary
              int endPos = dataEndInBytes;
              if (endPos >= 2 && bytes[endPos - 2] == 13 && bytes[endPos - 1] == 10) {
                endPos -= 2;
              }
              if (endPos > dataStartInBytes) {
                fileBytes = bytes.sublist(dataStartInBytes, endPos);
              }
            }
          }
        }
        // Check if this part contains the path field
        else if (part.contains('name="path"')) {
          final headerEndIndex = part.indexOf('\r\n\r\n');
          if (headerEndIndex != -1) {
            final dataStart = headerEndIndex + 4;
            final lines = part.substring(dataStart).split('\r\n');
            if (lines.isNotEmpty) {
              targetPath = lines[0].trim();
            }
          }
        }
      }
      
      if (fileName == null || fileBytes == null || fileBytes.isEmpty) {
        return Response.badRequest(body: jsonEncode({'error': 'No valid file found'}));
      }

      // Get target directory
      final baseDir = await _getStorageDirectory();
      final path = targetPath ?? '';
      final fullPath = path.isEmpty ? fileName : '$path/$fileName';
      final file = File('${baseDir.path}/$fullPath');

      await file.parent.create(recursive: true);
      await file.writeAsBytes(fileBytes);

      await logger.log(clientIp, 'UPLOAD: $fullPath (${fileBytes.length} bytes)');

      return Response.ok(
        jsonEncode({'success': true, 'path': fullPath}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stackTrace) {
      print('Upload error: $e\n$stackTrace');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Upload failed: $e'}),
      );
    }
  }

  Future<Response> _handleDelete(Request request, LoggerService logger, String clientIp) async {
    final body = await request.readAsString();
    final data = jsonDecode(body);
    final filePath = data['path'];

    if (filePath == null) {
      return Response.badRequest(body: jsonEncode({'error': 'Path parameter required'}));
    }

    final baseDir = await _getStorageDirectory();
    final file = File('${baseDir.path}/$filePath');
    final dir = Directory('${baseDir.path}/$filePath');

    if (await file.exists()) {
      await file.delete();
      await logger.log(clientIp, 'DELETE: $filePath');
      return Response.ok(jsonEncode({'success': true}));
    } else if (await dir.exists()) {
      await dir.delete(recursive: true);
      await logger.log(clientIp, 'DELETE: $filePath (directory)');
      return Response.ok(jsonEncode({'success': true}));
    }

    return Response.notFound(jsonEncode({'error': 'File or directory not found'}));
  }

  Future<Response> _handleRename(Request request, LoggerService logger, String clientIp) async {
    final body = await request.readAsString();
    final data = jsonDecode(body);
    final oldPath = data['oldPath'];
    final newName = data['newName'];

    if (oldPath == null || newName == null) {
      return Response.badRequest(body: jsonEncode({'error': 'oldPath and newName required'}));
    }

    final baseDir = await _getStorageDirectory();
    final oldFile = File('${baseDir.path}/$oldPath');
    final oldDir = Directory('${baseDir.path}/$oldPath');

    // Handle path for files in root vs subdirectories
    final lastSlashIndex = oldPath.lastIndexOf('/');
    final parentPath = lastSlashIndex >= 0 ? oldPath.substring(0, lastSlashIndex + 1) : '';
    final newPath = parentPath.isEmpty ? newName : '$parentPath$newName';
    final newFile = File('${baseDir.path}/$newPath');

    if (await oldFile.exists()) {
      await oldFile.rename(newFile.path);
      await logger.log(clientIp, 'RENAME: $oldPath -> $newPath');
      return Response.ok(jsonEncode({'success': true, 'newPath': newPath}));
    } else if (await oldDir.exists()) {
      await oldDir.rename('${baseDir.path}/$newPath');
      await logger.log(clientIp, 'RENAME: $oldPath -> $newPath (directory)');
      return Response.ok(jsonEncode({'success': true, 'newPath': newPath}));
    }

    return Response.notFound(jsonEncode({'error': 'File or directory not found'}));
  }

  Future<Response> _handleMkdir(Request request, LoggerService logger, String clientIp) async {
    final body = await request.readAsString();
    final data = jsonDecode(body);
    final dirPath = data['path'];

    if (dirPath == null) {
      return Response.badRequest(body: jsonEncode({'error': 'Path parameter required'}));
    }

    final baseDir = await _getStorageDirectory();
    final dir = Directory('${baseDir.path}/$dirPath');

    await dir.create(recursive: true);
    await logger.log(clientIp, 'MKDIR: $dirPath');

    return Response.ok(jsonEncode({'success': true}));
  }

  Response _serveIndexHtml() {
    // Note: Language is set to zh-TW (Traditional Chinese) as per requirements.
    // To support other languages, consider parameterizing this or using i18n.
    final html = '''
<!DOCTYPE html>
<html lang="zh-TW">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>檔案伺服器</title>
    <script src="https://unpkg.com/vue@3/dist/vue.global.js"></script>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@1/css/pico.min.css">
    <style>
        body { padding: 20px; }
        .file-list { list-style: none; padding: 0; }
        .file-item { 
            padding: 10px; 
            margin: 5px 0; 
            background: #f5f5f5; 
            border-radius: 5px;
            cursor: pointer;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .file-item:hover { background: #e0e0e0; }
        .file-item.selected { background: #b3d9ff; }
        .file-item.folder { font-weight: bold; }
        .toolbar { margin-bottom: 20px; display: flex; gap: 10px; flex-wrap: wrap; }
        .breadcrumb { margin-bottom: 10px; }
        .breadcrumb a { margin-right: 5px; color: #0066cc; cursor: pointer; }
        .drop-zone { 
            border: 2px dashed #ccc; 
            border-radius: 5px; 
            padding: 20px; 
            text-align: center; 
            margin-bottom: 20px;
        }
        .drop-zone.dragover { border-color: #0066cc; background: #e6f2ff; }
        .file-actions { display: flex; gap: 5px; }
    </style>
</head>
<body>
    <div id="app">
        <h1>📁 檔案伺服器</h1>
        
        <div class="breadcrumb">
            <a @click="navigateTo('')">根目錄</a>
            <span v-for="(part, index) in pathParts" :key="index">
                / <a @click="navigateTo(getPathUpTo(index))">{{ part }}</a>
            </span>
        </div>

        <div class="toolbar">
            <button @click="goUp" :disabled="currentPath === ''">⬆️ 上一層</button>
            <button @click="refresh">🔄 重新整理</button>
            <button @click="showUploadDialog">📤 上傳檔案</button>
            <button @click="showNewFolderDialog">📁 新增資料夾</button>
            <button @click="deleteSelected" :disabled="selectedFiles.length === 0">🗑️ 刪除</button>
            <button @click="showRenameDialog" :disabled="selectedFiles.length !== 1">✏️ 重新命名</button>
        </div>

        <div class="drop-zone" 
             @dragover.prevent="dragOver" 
             @dragleave.prevent="dragLeave"
             @drop.prevent="dropFiles"
             :class="{ dragover: isDragging }">
            拖曳檔案到此處上傳
        </div>

        <ul class="file-list">
            <li v-for="file in files" 
                :key="file.path"
                :class="['file-item', { folder: file.isDirectory, selected: isSelected(file) }]"
                @click="selectFile(file, $event)"
                @dblclick="openFile(file)">
                <span>
                    {{ file.isDirectory ? '📁' : '📄' }} {{ file.name }}
                    <small v-if="!file.isDirectory">({{ formatSize(file.size) }})</small>
                </span>
                <div class="file-actions">
                    <button @click.stop="downloadFile(file)" v-if="!file.isDirectory" class="secondary">下載</button>
                </div>
            </li>
        </ul>

        <input type="file" ref="fileInput" style="display: none" multiple @change="uploadFiles">
    </div>

    <script>
        const { createApp } = Vue;

        createApp({
            data() {
                return {
                    files: [],
                    currentPath: '',
                    selectedFiles: [],
                    isDragging: false,
                    copiedFiles: []
                }
            },
            computed: {
                pathParts() {
                    return this.currentPath ? this.currentPath.split('/') : [];
                }
            },
            mounted() {
                this.loadFiles();
                document.addEventListener('keydown', this.handleKeyboard);
            },
            beforeUnmount() {
                document.removeEventListener('keydown', this.handleKeyboard);
            },
            methods: {
                async loadFiles() {
                    try {
                        const response = await fetch(\`/api/list?path=\${encodeURIComponent(this.currentPath)}\`);
                        const data = await response.json();
                        this.files = data.files.sort((a, b) => {
                            if (a.isDirectory !== b.isDirectory) {
                                return a.isDirectory ? -1 : 1;
                            }
                            return a.name.localeCompare(b.name);
                        });
                    } catch (error) {
                        alert('載入檔案失敗: ' + error.message);
                    }
                },
                navigateTo(path) {
                    this.currentPath = path;
                    this.selectedFiles = [];
                    this.loadFiles();
                },
                getPathUpTo(index) {
                    return this.pathParts.slice(0, index + 1).join('/');
                },
                goUp() {
                    if (this.currentPath === '') return;
                    const parts = this.currentPath.split('/');
                    parts.pop();
                    this.navigateTo(parts.join('/'));
                },
                refresh() {
                    this.loadFiles();
                },
                selectFile(file, event) {
                    if (event.ctrlKey || event.metaKey) {
                        const index = this.selectedFiles.findIndex(f => f.path === file.path);
                        if (index >= 0) {
                            this.selectedFiles.splice(index, 1);
                        } else {
                            this.selectedFiles.push(file);
                        }
                    } else {
                        this.selectedFiles = [file];
                    }
                },
                isSelected(file) {
                    return this.selectedFiles.some(f => f.path === file.path);
                },
                openFile(file) {
                    if (file.isDirectory) {
                        this.navigateTo(file.path);
                    } else {
                        this.downloadFile(file);
                    }
                },
                async downloadFile(file) {
                    window.open(\`/api/get?path=\${encodeURIComponent(file.path)}\`, '_blank');
                },
                showUploadDialog() {
                    this.$refs.fileInput.click();
                },
                async uploadFiles(event) {
                    const files = event.target.files;
                    for (let file of files) {
                        await this.uploadFile(file);
                    }
                    this.$refs.fileInput.value = '';
                    this.loadFiles();
                },
                async uploadFile(file) {
                    const formData = new FormData();
                    formData.append('file', file);
                    formData.append('path', this.currentPath);

                    try {
                        await fetch('/api/upload', {
                            method: 'POST',
                            body: formData
                        });
                    } catch (error) {
                        alert('上傳失敗: ' + error.message);
                    }
                },
                async deleteSelected() {
                    if (!confirm(\`確定要刪除 \${this.selectedFiles.length} 個項目?\`)) return;

                    for (let file of this.selectedFiles) {
                        try {
                            await fetch('/api/delete', {
                                method: 'DELETE',
                                headers: { 'Content-Type': 'application/json' },
                                body: JSON.stringify({ path: file.path })
                            });
                        } catch (error) {
                            alert('刪除失敗: ' + error.message);
                        }
                    }
                    this.selectedFiles = [];
                    this.loadFiles();
                },
                showRenameDialog() {
                    const file = this.selectedFiles[0];
                    const newName = prompt('請輸入新名稱:', file.name);
                    if (newName && newName !== file.name) {
                        this.renameFile(file, newName);
                    }
                },
                async renameFile(file, newName) {
                    try {
                        await fetch('/api/rename', {
                            method: 'PUT',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({ oldPath: file.path, newName: newName })
                        });
                        this.selectedFiles = [];
                        this.loadFiles();
                    } catch (error) {
                        alert('重新命名失敗: ' + error.message);
                    }
                },
                showNewFolderDialog() {
                    const name = prompt('請輸入資料夾名稱:');
                    if (name) {
                        this.createFolder(name);
                    }
                },
                async createFolder(name) {
                    const path = this.currentPath ? \`\${this.currentPath}/\${name}\` : name;
                    try {
                        await fetch('/api/mkdir', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({ path: path })
                        });
                        this.loadFiles();
                    } catch (error) {
                        alert('建立資料夾失敗: ' + error.message);
                    }
                },
                dragOver(event) {
                    this.isDragging = true;
                },
                dragLeave(event) {
                    this.isDragging = false;
                },
                async dropFiles(event) {
                    this.isDragging = false;
                    const files = event.dataTransfer.files;
                    for (let file of files) {
                        await this.uploadFile(file);
                    }
                    this.loadFiles();
                },
                handleKeyboard(event) {
                    if (event.ctrlKey && event.key === 'c') {
                        this.copiedFiles = [...this.selectedFiles];
                    } else if (event.ctrlKey && event.key === 'v' && this.copiedFiles.length > 0) {
                        // Copy functionality would require additional server-side support
                        alert('複製功能需要伺服器端額外支援');
                    }
                },
                formatSize(bytes) {
                    if (bytes === 0) return '0 B';
                    const k = 1024;
                    const sizes = ['B', 'KB', 'MB', 'GB'];
                    const i = Math.floor(Math.log(bytes) / Math.log(k));
                    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
                }
            }
        }).mount('#app');
    </script>
</body>
</html>
    ''';

    return Response.ok(
      html,
      headers: {'Content-Type': 'text/html; charset=utf-8'},
    );
  }

  Future<Directory> _getStorageDirectory() async {
    // For Android, get the external storage directory
    Directory? directory;
    
    if (Platform.isAndroid) {
      directory = await getExternalStorageDirectory();
      if (directory != null) {
        // Navigate to the root of external storage
        final paths = directory.path.split('/');
        final storageIndex = paths.indexOf('Android');
        if (storageIndex >= 0) {
          final storagePath = paths.sublist(0, storageIndex).join('/');
          directory = Directory(storagePath);
        }
      }
    }
    
    directory ??= await getApplicationDocumentsDirectory();
    
    return directory;
  }
}
