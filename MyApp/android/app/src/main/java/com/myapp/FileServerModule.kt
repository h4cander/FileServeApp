package com.myapp

import android.content.Context
import android.os.Environment
import android.util.Log
import com.facebook.react.bridge.*
import com.facebook.react.modules.core.DeviceEventManagerModule
import fi.iki.elonen.NanoHTTPD
import org.json.JSONArray
import org.json.JSONObject
import java.io.*
import java.net.InetAddress
import java.net.NetworkInterface
import java.text.SimpleDateFormat
import java.util.*

class FileServerModule(reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext) {
    private var server: FileServer? = null
    private val context: Context = reactContext

    override fun getName(): String {
        return "FileServer"
    }

    @ReactMethod
    fun startServer(port: Int, promise: Promise) {
        try {
            if (server != null && server!!.isAlive) {
                promise.reject("SERVER_RUNNING", "Server is already running")
                return
            }

            server = FileServer(context, reactApplicationContext, port)
            server!!.start()
            
            val ipAddress = getIPAddress()
            val result = Arguments.createMap()
            result.putString("ip", ipAddress)
            result.putInt("port", port)
            result.putString("url", "http://$ipAddress:$port")
            
            promise.resolve(result)
        } catch (e: Exception) {
            promise.reject("START_ERROR", e.message)
        }
    }

    @ReactMethod
    fun stopServer(promise: Promise) {
        try {
            server?.stop()
            server = null
            promise.resolve("Server stopped")
        } catch (e: Exception) {
            promise.reject("STOP_ERROR", e.message)
        }
    }

    @ReactMethod
    fun isServerRunning(promise: Promise) {
        promise.resolve(server?.isAlive ?: false)
    }

    @ReactMethod
    fun getLogs(date: String, promise: Promise) {
        try {
            val logFile = File(context.getExternalFilesDir(null), "$date.log")
            if (!logFile.exists()) {
                promise.resolve("")
                return
            }

            val logs = logFile.readText()
            promise.resolve(logs)
        } catch (e: Exception) {
            promise.reject("LOG_ERROR", e.message)
        }
    }

    @ReactMethod
    fun getLogDates(promise: Promise) {
        try {
            val logDir = context.getExternalFilesDir(null)
            val logFiles = logDir?.listFiles { file ->
                file.name.matches(Regex("\\d{8}\\.log"))
            }?.sortedByDescending { it.name } ?: emptyList()

            val dates = Arguments.createArray()
            logFiles.forEach { file ->
                dates.pushString(file.name.replace(".log", ""))
            }
            promise.resolve(dates)
        } catch (e: Exception) {
            promise.reject("LOG_DATES_ERROR", e.message)
        }
    }

    private fun getIPAddress(): String {
        try {
            val interfaces = NetworkInterface.getNetworkInterfaces()
            while (interfaces.hasMoreElements()) {
                val networkInterface = interfaces.nextElement()
                val addresses = networkInterface.inetAddresses
                while (addresses.hasMoreElements()) {
                    val address = addresses.nextElement()
                    if (!address.isLoopbackAddress && address is java.net.Inet4Address) {
                        return address.hostAddress ?: "0.0.0.0"
                    }
                }
            }
        } catch (e: Exception) {
            Log.e("FileServer", "Failed to get IP", e)
        }
        return "0.0.0.0"
    }

    private fun logOperation(clientIp: String, operation: String, path: String) {
        try {
            val dateFormat = SimpleDateFormat("yyyyMMdd", Locale.getDefault())
            val timeFormat = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault())
            val date = dateFormat.format(Date())
            val time = timeFormat.format(Date())

            val logFile = File(context.getExternalFilesDir(null), "$date.log")
            val logEntry = "$time | $clientIp | $operation | $path\n"
            
            logFile.appendText(logEntry)

            // Send event to React Native
            reactApplicationContext
                .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
                .emit("newLogEntry", logEntry.trim())
        } catch (e: Exception) {
            Log.e("FileServer", "Failed to log operation", e)
        }
    }

    inner class FileServer(
        private val context: Context,
        private val reactContext: ReactApplicationContext,
        port: Int
    ) : NanoHTTPD(port) {

        private val baseDir: File = Environment.getExternalStorageDirectory()

        override fun serve(session: IHTTPSession): Response {
            val uri = session.uri
            val method = session.method
            val clientIp = session.remoteIpAddress

            return try {
                when {
                    uri == "/" || uri == "/index.html" -> serveIndexHtml()
                    uri.startsWith("/api/list") -> handleList(session, clientIp)
                    uri.startsWith("/api/get") -> handleGet(session, clientIp)
                    uri.startsWith("/api/upload") -> handleUpload(session, clientIp)
                    uri.startsWith("/api/delete") -> handleDelete(session, clientIp)
                    uri.startsWith("/api/rename") -> handleRename(session, clientIp)
                    uri.startsWith("/api/mkdir") -> handleMkdir(session, clientIp)
                    else -> newFixedLengthResponse(Response.Status.NOT_FOUND, MIME_PLAINTEXT, "Not Found")
                }
            } catch (e: Exception) {
                Log.e("FileServer", "Error handling request", e)
                newFixedLengthResponse(Response.Status.INTERNAL_ERROR, MIME_PLAINTEXT, e.message)
            }
        }

        private fun serveIndexHtml(): Response {
            val html = """
<!DOCTYPE html>
<html lang="zh-TW">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>File Server</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: Arial, sans-serif; padding: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h1 { margin-bottom: 20px; color: #333; }
        .toolbar { display: flex; gap: 10px; margin-bottom: 20px; flex-wrap: wrap; align-items: center; }
        button { padding: 10px 20px; background: #4CAF50; color: white; border: none; border-radius: 4px; cursor: pointer; font-size: 14px; }
        button:hover { background: #45a049; }
        button:disabled { background: #ccc; cursor: not-allowed; }
        .btn-danger { background: #f44336; }
        .btn-danger:hover { background: #da190b; }
        .btn-secondary { background: #2196F3; }
        .btn-secondary:hover { background: #0b7dda; }
        #currentPath { flex: 1; padding: 10px; border: 1px solid #ddd; border-radius: 4px; background: #f9f9f9; }
        .file-list { list-style: none; }
        .file-item { padding: 12px; border-bottom: 1px solid #eee; display: flex; align-items: center; gap: 10px; cursor: pointer; transition: background 0.2s; }
        .file-item:hover { background: #f5f5f5; }
        .file-item.selected { background: #e3f2fd; }
        .file-icon { font-size: 20px; }
        .file-name { flex: 1; }
        .file-size { color: #666; font-size: 12px; min-width: 80px; text-align: right; }
        .file-actions { display: flex; gap: 5px; }
        .file-actions button { padding: 5px 10px; font-size: 12px; }
        input[type="file"] { display: none; }
        .drop-zone { border: 2px dashed #ddd; border-radius: 4px; padding: 40px; text-align: center; color: #999; margin: 20px 0; }
        .drop-zone.dragover { border-color: #4CAF50; background: #f0f8f0; color: #4CAF50; }
        .modal { display: none; position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.5); z-index: 1000; justify-content: center; align-items: center; }
        .modal.show { display: flex; }
        .modal-content { background: white; padding: 20px; border-radius: 8px; min-width: 300px; }
        .modal-content input { width: 100%; padding: 10px; margin: 10px 0; border: 1px solid #ddd; border-radius: 4px; }
        .modal-actions { display: flex; gap: 10px; justify-content: flex-end; margin-top: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>📁 File Server</h1>
        <div class="toolbar">
            <button onclick="goUp()">⬆️ 上一層</button>
            <button onclick="refresh()">🔄 重新整理</button>
            <button onclick="showNewFolderDialog()">📁 新增資料夾</button>
            <button onclick="document.getElementById('fileInput').click()">📤 上傳檔案</button>
            <div id="currentPath">/</div>
        </div>
        
        <div class="drop-zone" id="dropZone">
            拖曳檔案到此處上傳
        </div>
        
        <input type="file" id="fileInput" multiple onchange="uploadFiles(this.files)">
        
        <ul class="file-list" id="fileList"></ul>
    </div>

    <!-- Rename Modal -->
    <div class="modal" id="renameModal">
        <div class="modal-content">
            <h3>重新命名</h3>
            <input type="text" id="renameInput" placeholder="新名稱">
            <div class="modal-actions">
                <button class="btn-secondary" onclick="closeModal()">取消</button>
                <button onclick="confirmRename()">確定</button>
            </div>
        </div>
    </div>

    <!-- New Folder Modal -->
    <div class="modal" id="newFolderModal">
        <div class="modal-content">
            <h3>新增資料夾</h3>
            <input type="text" id="folderNameInput" placeholder="資料夾名稱">
            <div class="modal-actions">
                <button class="btn-secondary" onclick="closeModal()">取消</button>
                <button onclick="confirmNewFolder()">確定</button>
            </div>
        </div>
    </div>

    <script>
        let currentPath = '/';
        let selectedItems = new Set();
        let clipboard = null;
        let clipboardOperation = null; // 'copy' or 'cut'
        let renameTarget = null;

        // Load initial file list
        loadFiles();

        // Drag and drop
        const dropZone = document.getElementById('dropZone');
        dropZone.addEventListener('dragover', (e) => {
            e.preventDefault();
            dropZone.classList.add('dragover');
        });
        dropZone.addEventListener('dragleave', () => {
            dropZone.classList.remove('dragover');
        });
        dropZone.addEventListener('drop', (e) => {
            e.preventDefault();
            dropZone.classList.remove('dragover');
            uploadFiles(e.dataTransfer.files);
        });

        // Keyboard shortcuts
        document.addEventListener('keydown', (e) => {
            if (e.ctrlKey && e.key === 'c') {
                e.preventDefault();
                copy();
            } else if (e.ctrlKey && e.key === 'v') {
                e.preventDefault();
                paste();
            } else if (e.ctrlKey && e.key === 'x') {
                e.preventDefault();
                cut();
            }
        });

        async function loadFiles(path = currentPath) {
            try {
                const response = await fetch(`/api/list?path=$${encodeURIComponent(path)}`);
                const data = await response.json();
                
                if (data.error) {
                    alert('錯誤: ' + data.error);
                    return;
                }

                currentPath = data.path;
                document.getElementById('currentPath').textContent = currentPath;

                const fileList = document.getElementById('fileList');
                fileList.innerHTML = '';

                data.files.forEach(file => {
                    const li = document.createElement('li');
                    li.className = 'file-item';
                    li.dataset.path = file.path;
                    li.dataset.isDir = file.isDirectory;
                    
                    li.innerHTML = `
                        <span class="file-icon">${'${file.isDirectory ? "📁" : "📄"}'}</span>
                        <span class="file-name">${'${file.name}'}</span>
                        <span class="file-size">${'${file.isDirectory ? "" : formatSize(file.size)}'}</span>
                        <div class="file-actions">
                            <button class="btn-secondary" onclick="renameFile(event, '${'${file.path}'}', '${'${file.name}'}')">重新命名</button>
                            <button class="btn-danger" onclick="deleteFile(event, '${'${file.path}'}')">刪除</button>
                        </div>
                    `;

                    if (file.isDirectory) {
                        li.addEventListener('dblclick', () => loadFiles(file.path));
                    } else {
                        li.addEventListener('dblclick', () => downloadFile(file.path));
                    }

                    li.addEventListener('click', (e) => {
                        if (!e.ctrlKey) {
                            document.querySelectorAll('.file-item').forEach(item => item.classList.remove('selected'));
                            selectedItems.clear();
                        }
                        li.classList.toggle('selected');
                        if (li.classList.contains('selected')) {
                            selectedItems.add(file.path);
                        } else {
                            selectedItems.delete(file.path);
                        }
                    });

                    fileList.appendChild(li);
                });
            } catch (error) {
                alert('載入檔案失敗: ' + error.message);
            }
        }

        function goUp() {
            if (currentPath === '/') return;
            const parts = currentPath.split('/').filter(p => p);
            parts.pop();
            const newPath = '/' + parts.join('/');
            loadFiles(newPath);
        }

        function refresh() {
            loadFiles(currentPath);
        }

        async function uploadFiles(files) {
            for (let file of files) {
                const formData = new FormData();
                formData.append('file', file);
                formData.append('path', currentPath);

                try {
                    const response = await fetch('/api/upload', {
                        method: 'POST',
                        body: formData
                    });
                    const result = await response.json();
                    if (result.error) {
                        alert('上傳失敗: ' + result.error);
                    }
                } catch (error) {
                    alert('上傳失敗: ' + error.message);
                }
            }
            loadFiles();
        }

        async function deleteFile(event, path) {
            event.stopPropagation();
            if (!confirm('確定要刪除嗎？')) return;

            try {
                const response = await fetch(`/api/delete?path=${'${encodeURIComponent(path)}'}`, {
                    method: 'DELETE'
                });
                const result = await response.json();
                if (result.error) {
                    alert('刪除失敗: ' + result.error);
                } else {
                    loadFiles();
                }
            } catch (error) {
                alert('刪除失敗: ' + error.message);
            }
        }

        function renameFile(event, path, oldName) {
            event.stopPropagation();
            renameTarget = path;
            document.getElementById('renameInput').value = oldName;
            document.getElementById('renameModal').classList.add('show');
        }

        async function confirmRename() {
            const newName = document.getElementById('renameInput').value.trim();
            if (!newName) {
                alert('請輸入新名稱');
                return;
            }

            try {
                const response = await fetch('/api/rename', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ oldPath: renameTarget, newName: newName })
                });
                const result = await response.json();
                if (result.error) {
                    alert('重新命名失敗: ' + result.error);
                } else {
                    closeModal();
                    loadFiles();
                }
            } catch (error) {
                alert('重新命名失敗: ' + error.message);
            }
        }

        function showNewFolderDialog() {
            document.getElementById('folderNameInput').value = '';
            document.getElementById('newFolderModal').classList.add('show');
        }

        async function confirmNewFolder() {
            const folderName = document.getElementById('folderNameInput').value.trim();
            if (!folderName) {
                alert('請輸入資料夾名稱');
                return;
            }

            try {
                const response = await fetch('/api/mkdir', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ path: currentPath, name: folderName })
                });
                const result = await response.json();
                if (result.error) {
                    alert('建立資料夾失敗: ' + result.error);
                } else {
                    closeModal();
                    loadFiles();
                }
            } catch (error) {
                alert('建立資料夾失敗: ' + error.message);
            }
        }

        function closeModal() {
            document.querySelectorAll('.modal').forEach(modal => modal.classList.remove('show'));
        }

        function downloadFile(path) {
            window.open(`/api/get?path=${'${encodeURIComponent(path)}'}`, '_blank');
        }

        function copy() {
            if (selectedItems.size === 0) return;
            clipboard = Array.from(selectedItems);
            clipboardOperation = 'copy';
            console.log('已複製', clipboard);
        }

        function cut() {
            if (selectedItems.size === 0) return;
            clipboard = Array.from(selectedItems);
            clipboardOperation = 'cut';
            console.log('已剪下', clipboard);
        }

        async function paste() {
            if (!clipboard || clipboard.length === 0) return;

            // Note: This would require additional server API for copy/move operations
            alert('複製/貼上功能需要額外的API支援');
        }

        function formatSize(bytes) {
            if (bytes === 0) return '0 B';
            const k = 1024;
            const sizes = ['B', 'KB', 'MB', 'GB'];
            const i = Math.floor(Math.log(bytes) / Math.log(k));
            return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
        }
    </script>
</body>
</html>
            """.trimIndent()

            return newFixedLengthResponse(Response.Status.OK, "text/html", html)
        }

        private fun handleList(session: IHTTPSession, clientIp: String): Response {
            val params = session.parms
            val path = params["path"] ?: "/"
            
            val targetDir = File(baseDir, path)
            
            if (!targetDir.exists() || !targetDir.isDirectory) {
                val json = JSONObject()
                json.put("error", "Directory not found")
                return newFixedLengthResponse(Response.Status.NOT_FOUND, "application/json", json.toString())
            }

            logOperation(clientIp, "LIST", path)

            val files = targetDir.listFiles()?.sortedWith(compareBy({ !it.isDirectory }, { it.name })) ?: emptyList()
            
            val jsonArray = JSONArray()
            files.forEach { file ->
                val fileObj = JSONObject()
                fileObj.put("name", file.name)
                fileObj.put("path", file.absolutePath.removePrefix(baseDir.absolutePath))
                fileObj.put("isDirectory", file.isDirectory)
                fileObj.put("size", if (file.isDirectory) 0 else file.length())
                fileObj.put("modified", file.lastModified())
                jsonArray.put(fileObj)
            }

            val result = JSONObject()
            result.put("path", path)
            result.put("files", jsonArray)

            return newFixedLengthResponse(Response.Status.OK, "application/json", result.toString())
        }

        private fun handleGet(session: IHTTPSession, clientIp: String): Response {
            val params = session.parms
            val path = params["path"] ?: return newFixedLengthResponse(
                Response.Status.BAD_REQUEST,
                MIME_PLAINTEXT,
                "Missing path parameter"
            )

            val file = File(baseDir, path)
            
            if (!file.exists() || !file.isFile) {
                return newFixedLengthResponse(Response.Status.NOT_FOUND, MIME_PLAINTEXT, "File not found")
            }

            logOperation(clientIp, "GET", path)

            val mimeType = getMimeType(file.name)
            return newChunkedResponse(Response.Status.OK, mimeType, FileInputStream(file))
        }

        private fun handleUpload(session: IHTTPSession, clientIp: String): Response {
            val files = HashMap<String, String>()
            session.parseBody(files)

            val path = session.parms["path"] ?: "/"
            val targetDir = File(baseDir, path)

            if (!targetDir.exists() || !targetDir.isDirectory) {
                val json = JSONObject()
                json.put("error", "Directory not found")
                return newFixedLengthResponse(Response.Status.NOT_FOUND, "application/json", json.toString())
            }

            files.forEach { (key, tmpFile) ->
                if (key == "file") {
                    val fileName = session.parms["file"] ?: "uploaded_file"
                    val targetFile = File(targetDir, fileName)
                    File(tmpFile).copyTo(targetFile, overwrite = true)
                    logOperation(clientIp, "UPLOAD", "${path}/${fileName}")
                }
            }

            val result = JSONObject()
            result.put("success", true)
            return newFixedLengthResponse(Response.Status.OK, "application/json", result.toString())
        }

        private fun handleDelete(session: IHTTPSession, clientIp: String): Response {
            val params = session.parms
            val path = params["path"] ?: return newFixedLengthResponse(
                Response.Status.BAD_REQUEST,
                "application/json",
                JSONObject().put("error", "Missing path parameter").toString()
            )

            val file = File(baseDir, path)
            
            if (!file.exists()) {
                return newFixedLengthResponse(
                    Response.Status.NOT_FOUND,
                    "application/json",
                    JSONObject().put("error", "File not found").toString()
                )
            }

            val deleted = file.deleteRecursively()
            logOperation(clientIp, "DELETE", path)

            val result = JSONObject()
            result.put("success", deleted)
            return newFixedLengthResponse(Response.Status.OK, "application/json", result.toString())
        }

        private fun handleRename(session: IHTTPSession, clientIp: String): Response {
            val files = HashMap<String, String>()
            session.parseBody(files)

            val bodyStr = files["postData"] ?: return newFixedLengthResponse(
                Response.Status.BAD_REQUEST,
                "application/json",
                JSONObject().put("error", "Missing body").toString()
            )

            val jsonBody = JSONObject(bodyStr)
            val oldPath = jsonBody.getString("oldPath")
            val newName = jsonBody.getString("newName")

            val oldFile = File(baseDir, oldPath)
            if (!oldFile.exists()) {
                return newFixedLengthResponse(
                    Response.Status.NOT_FOUND,
                    "application/json",
                    JSONObject().put("error", "File not found").toString()
                )
            }

            val newFile = File(oldFile.parentFile, newName)
            val renamed = oldFile.renameTo(newFile)
            
            if (renamed) {
                logOperation(clientIp, "RENAME", "$oldPath -> ${newFile.absolutePath.removePrefix(baseDir.absolutePath)}")
            }

            val result = JSONObject()
            result.put("success", renamed)
            return newFixedLengthResponse(Response.Status.OK, "application/json", result.toString())
        }

        private fun handleMkdir(session: IHTTPSession, clientIp: String): Response {
            val files = HashMap<String, String>()
            session.parseBody(files)

            val bodyStr = files["postData"] ?: return newFixedLengthResponse(
                Response.Status.BAD_REQUEST,
                "application/json",
                JSONObject().put("error", "Missing body").toString()
            )

            val jsonBody = JSONObject(bodyStr)
            val path = jsonBody.getString("path")
            val name = jsonBody.getString("name")

            val parentDir = File(baseDir, path)
            if (!parentDir.exists() || !parentDir.isDirectory) {
                return newFixedLengthResponse(
                    Response.Status.NOT_FOUND,
                    "application/json",
                    JSONObject().put("error", "Parent directory not found").toString()
                )
            }

            val newDir = File(parentDir, name)
            val created = newDir.mkdir()
            
            if (created) {
                logOperation(clientIp, "MKDIR", "${path}/${name}")
            }

            val result = JSONObject()
            result.put("success", created)
            return newFixedLengthResponse(Response.Status.OK, "application/json", result.toString())
        }

        private fun getMimeType(fileName: String): String {
            return when (fileName.substringAfterLast('.', "").lowercase()) {
                "html", "htm" -> "text/html"
                "txt" -> "text/plain"
                "css" -> "text/css"
                "js" -> "application/javascript"
                "json" -> "application/json"
                "png" -> "image/png"
                "jpg", "jpeg" -> "image/jpeg"
                "gif" -> "image/gif"
                "svg" -> "image/svg+xml"
                "pdf" -> "application/pdf"
                "zip" -> "application/zip"
                "mp4" -> "video/mp4"
                "mp3" -> "audio/mpeg"
                else -> "application/octet-stream"
            }
        }
    }
}
