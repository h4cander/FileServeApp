# API Documentation

## Base URL

```
http://[device-ip]:8080
```

Where `[device-ip]` is the IP address shown in the app (e.g., `192.168.1.100`)

## Authentication

Currently, no authentication is required. All endpoints are publicly accessible on the local network.

⚠️ **Security Warning**: This server is designed for use on trusted local networks only. Do not expose it to the internet without adding proper authentication.

## Endpoints

### 1. Serve Web Interface

**GET** `/`

Serves the HTML web interface for file management.

**Response:**
- **200 OK**: Returns HTML page
- **Content-Type**: `text/html; charset=utf-8`

---

### 2. List Files

**GET** `/api/list`

Lists all files and directories in the specified path.

**Query Parameters:**
- `path` (string, optional): Relative path from storage root. Empty string or omitted for root directory.

**Example Request:**
```
GET /api/list?path=Documents/Photos
```

**Response:**
```json
{
  "files": [
    {
      "name": "image.jpg",
      "path": "Documents/Photos/image.jpg",
      "isDirectory": false,
      "size": 1024000,
      "modified": "2024-01-15T10:30:00.000Z"
    },
    {
      "name": "Vacation",
      "path": "Documents/Photos/Vacation",
      "isDirectory": true,
      "size": 0,
      "modified": "2024-01-14T15:20:00.000Z"
    }
  ],
  "currentPath": "Documents/Photos"
}
```

**Response Codes:**
- **200 OK**: Success
- **404 Not Found**: Directory does not exist
- **500 Internal Server Error**: Server error

**Logged As:** `LIST: [path]`

---

### 3. Download File

**GET** `/api/get`

Downloads a specific file.

**Query Parameters:**
- `path` (string, required): Relative path to the file from storage root.

**Example Request:**
```
GET /api/get?path=Documents/report.pdf
```

**Response:**
- **200 OK**: Returns file contents
- **Content-Type**: `application/octet-stream`
- **Content-Disposition**: `attachment; filename="[filename]"`

**Response Codes:**
- **200 OK**: Success
- **400 Bad Request**: Path parameter missing
- **404 Not Found**: File does not exist
- **500 Internal Server Error**: Server error

**Logged As:** `GET: [path]`

---

### 4. Upload File

**POST** `/api/upload`

Uploads a file to the specified directory.

**Content-Type:** `multipart/form-data`

**Form Fields:**
- `file` (file, required): The file to upload
- `path` (string, optional): Target directory path. Empty for root.

**Example Request:**
```javascript
const formData = new FormData();
formData.append('file', fileObject);
formData.append('path', 'Documents/Photos');

fetch('/api/upload', {
  method: 'POST',
  body: formData
});
```

**Response:**
```json
{
  "success": true,
  "path": "Documents/Photos/image.jpg"
}
```

**Response Codes:**
- **200 OK**: Success
- **400 Bad Request**: Invalid content type or no file provided
- **500 Internal Server Error**: Upload failed

**Logged As:** `UPLOAD: [path] ([size] bytes)`

---

### 5. Delete File/Directory

**DELETE** `/api/delete`

Deletes a file or directory (recursive).

**Content-Type:** `application/json`

**Request Body:**
```json
{
  "path": "Documents/old-file.txt"
}
```

**Response:**
```json
{
  "success": true
}
```

**Response Codes:**
- **200 OK**: Success
- **400 Bad Request**: Path parameter missing
- **404 Not Found**: File or directory does not exist
- **500 Internal Server Error**: Delete failed

**Logged As:** `DELETE: [path]` or `DELETE: [path] (directory)`

---

### 6. Rename File/Directory

**PUT** `/api/rename`

Renames a file or directory.

**Content-Type:** `application/json`

**Request Body:**
```json
{
  "oldPath": "Documents/old-name.txt",
  "newName": "new-name.txt"
}
```

**Response:**
```json
{
  "success": true,
  "newPath": "Documents/new-name.txt"
}
```

**Response Codes:**
- **200 OK**: Success
- **400 Bad Request**: Missing required parameters
- **404 Not Found**: File or directory does not exist
- **500 Internal Server Error**: Rename failed

**Logged As:** `RENAME: [oldPath] -> [newPath]` or `RENAME: [oldPath] -> [newPath] (directory)`

---

### 7. Create Directory

**POST** `/api/mkdir`

Creates a new directory (with parent directories if needed).

**Content-Type:** `application/json`

**Request Body:**
```json
{
  "path": "Documents/New Folder"
}
```

**Response:**
```json
{
  "success": true
}
```

**Response Codes:**
- **200 OK**: Success
- **400 Bad Request**: Path parameter missing
- **500 Internal Server Error**: Directory creation failed

**Logged As:** `MKDIR: [path]`

---

## CORS

All API endpoints include CORS headers:
```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, DELETE, PUT, OPTIONS
Access-Control-Allow-Headers: Content-Type, Authorization
```

## Error Response Format

All errors return JSON with an error message:

```json
{
  "error": "Error description here"
}
```

## Logging

All API requests are logged with:
- Timestamp (YYYY-MM-DD HH:MM:SS format)
- Client IP address
- Operation performed
- File path (if applicable)

Logs are stored in `[app-data]/logs/[YYYYMMDD].log`

## Rate Limiting

Currently, no rate limiting is implemented. All requests are processed immediately.

## File Size Limits

No explicit file size limits are enforced by the API. Limits are determined by:
- Available storage space on device
- Memory available to the app
- Network timeout settings

## Path Handling

- Paths are relative to the storage root directory
- Use forward slashes (`/`) as path separators
- Do not include leading or trailing slashes
- Empty string represents the root directory

**Valid paths:**
- `""` (root)
- `Documents`
- `Documents/Photos`
- `Documents/Photos/image.jpg`

**Invalid paths:**
- `/Documents` (leading slash)
- `Documents/` (trailing slash)
- `../etc/passwd` (path traversal)

## Client IP Detection

Client IP is determined from:
1. `X-Forwarded-For` header (if present)
2. Connection info from Shelf server
3. Falls back to "unknown" if neither is available

## Storage Location

Files are stored in the device's external storage root directory. On Android:
- Path: `/storage/emulated/0/` or similar
- Accessible via file manager apps
- Requires "All files access" permission on Android 14+

## Examples

### JavaScript/Fetch

```javascript
// List files
const response = await fetch('/api/list?path=Documents');
const data = await response.json();
console.log(data.files);

// Upload file
const formData = new FormData();
formData.append('file', fileInput.files[0]);
await fetch('/api/upload', { method: 'POST', body: formData });

// Delete file
await fetch('/api/delete', {
  method: 'DELETE',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ path: 'old-file.txt' })
});

// Rename file
await fetch('/api/rename', {
  method: 'PUT',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ oldPath: 'old.txt', newName: 'new.txt' })
});
```

### cURL

```bash
# List files
curl "http://192.168.1.100:8080/api/list?path=Documents"

# Download file
curl "http://192.168.1.100:8080/api/get?path=file.txt" -o file.txt

# Upload file
curl -X POST "http://192.168.1.100:8080/api/upload" \
  -F "file=@local-file.txt" \
  -F "path=Documents"

# Delete file
curl -X DELETE "http://192.168.1.100:8080/api/delete" \
  -H "Content-Type: application/json" \
  -d '{"path":"file.txt"}'

# Rename file
curl -X PUT "http://192.168.1.100:8080/api/rename" \
  -H "Content-Type: application/json" \
  -d '{"oldPath":"old.txt","newName":"new.txt"}'

# Create directory
curl -X POST "http://192.168.1.100:8080/api/mkdir" \
  -H "Content-Type: application/json" \
  -d '{"path":"NewFolder"}'
```

### Python

```python
import requests

base_url = "http://192.168.1.100:8080"

# List files
response = requests.get(f"{base_url}/api/list", params={"path": "Documents"})
files = response.json()["files"]

# Upload file
with open("file.txt", "rb") as f:
    files = {"file": f}
    data = {"path": "Documents"}
    response = requests.post(f"{base_url}/api/upload", files=files, data=data)

# Delete file
response = requests.delete(
    f"{base_url}/api/delete",
    json={"path": "file.txt"}
)

# Rename file
response = requests.put(
    f"{base_url}/api/rename",
    json={"oldPath": "old.txt", "newName": "new.txt"}
)
```
