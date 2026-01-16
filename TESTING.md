# Testing Guide

## Manual Testing Checklist

### App Functionality

#### 1. Initial Setup
- [ ] App installs successfully
- [ ] Permissions dialog appears on first run
- [ ] All requested permissions can be granted
- [ ] App UI loads correctly

#### 2. Server Start/Stop
- [ ] "開始" (Start) button is enabled when server is stopped
- [ ] Server starts successfully when "開始" is clicked
- [ ] Status changes to "啟動中..." then "運行中"
- [ ] Server URL is displayed correctly (http://192.168.x.x:8080)
- [ ] "停止" (Stop) button becomes enabled when server is running
- [ ] "開始" button becomes disabled when server is running
- [ ] Server stops successfully when "停止" is clicked
- [ ] Status changes to "未啟動" when stopped
- [ ] Server can be restarted after stopping

#### 3. Logging
- [ ] Log entries are created when server starts
- [ ] Log entries are created when server stops
- [ ] Logs are displayed in reverse chronological order (newest first)
- [ ] Date picker allows selecting different dates
- [ ] Logs from selected date are displayed correctly
- [ ] Log format includes timestamp, IP, and action
- [ ] Logs persist after app restart

### Web Interface Functionality

#### 1. Basic Navigation
- [ ] Web interface loads at http://[device-ip]:8080
- [ ] Page displays in Chinese (Traditional)
- [ ] File list loads correctly
- [ ] Breadcrumb navigation shows current path
- [ ] Clicking on breadcrumb navigates to that directory
- [ ] "上一層" (Up) button navigates to parent directory
- [ ] "上一層" button is disabled at root directory
- [ ] Double-clicking folder opens that folder
- [ ] Double-clicking file downloads that file

#### 2. File Upload
- [ ] "📤 上傳檔案" button opens file picker
- [ ] Single file can be uploaded
- [ ] Multiple files can be uploaded at once
- [ ] Files upload to current directory
- [ ] File list refreshes after upload
- [ ] Uploaded files appear in the list
- [ ] Drag and drop zone is visible
- [ ] Drag and drop zone highlights on dragover
- [ ] Files can be dropped to upload
- [ ] Large files (>10MB) upload successfully

#### 3. File Download
- [ ] Clicking "下載" button downloads file
- [ ] Double-clicking file downloads it
- [ ] Downloaded file has correct name
- [ ] Downloaded file content is correct
- [ ] Multiple files can be downloaded sequentially

#### 4. File Selection
- [ ] Clicking file selects it (highlighted in blue)
- [ ] Ctrl+Click adds file to selection
- [ ] Clicking another file without Ctrl deselects previous
- [ ] Multiple files can be selected
- [ ] Selected count updates correctly

#### 5. File Deletion
- [ ] "🗑️ 刪除" button is disabled when nothing selected
- [ ] "🗑️ 刪除" button is enabled when file(s) selected
- [ ] Confirmation dialog appears before deletion
- [ ] Single file can be deleted
- [ ] Multiple files can be deleted at once
- [ ] Folder can be deleted (recursive)
- [ ] File list refreshes after deletion
- [ ] Deleted files no longer appear

#### 6. File Rename
- [ ] "✏️ 重新命名" button is disabled when nothing selected
- [ ] "✏️ 重新命名" button is disabled when multiple files selected
- [ ] "✏️ 重新命名" button is enabled when one file selected
- [ ] Rename dialog appears with current name
- [ ] File is renamed successfully
- [ ] Renamed file appears with new name
- [ ] Folder can be renamed

#### 7. Folder Creation
- [ ] "📁 新增資料夾" button opens dialog
- [ ] Dialog prompts for folder name
- [ ] New folder is created successfully
- [ ] New folder appears in file list
- [ ] Can navigate into newly created folder

#### 8. Refresh
- [ ] "🔄 重新整理" button reloads file list
- [ ] External changes are reflected after refresh

### Log Functionality

#### 1. Log Recording
- [ ] Server start is logged
- [ ] Server stop is logged
- [ ] File list operations are logged with IP
- [ ] File download is logged with IP and filename
- [ ] File upload is logged with IP and filename
- [ ] File delete is logged with IP and filename
- [ ] File rename is logged with IP and old/new names
- [ ] Folder creation is logged with IP and folder name

#### 2. Log Viewing
- [ ] Logs appear in app immediately after operation
- [ ] Today's logs are shown by default
- [ ] Date picker allows selecting past dates
- [ ] Log format: [YYYY-MM-DD HH:MM:SS] IP - Action
- [ ] Logs are in reverse chronological order
- [ ] Empty date shows "無日誌記錄"

### Error Handling

#### 1. Network Errors
- [ ] Server start fails gracefully if port is in use
- [ ] Clear error message is displayed
- [ ] App doesn't crash on network errors

#### 2. File System Errors
- [ ] Permission denied errors are handled
- [ ] Non-existent path errors are handled
- [ ] Invalid filename errors are handled
- [ ] Disk full errors are handled

#### 3. Web Interface Errors
- [ ] 404 for non-existent files shows error
- [ ] Upload failures show error message
- [ ] Delete failures show error message
- [ ] Rename failures show error message

### Performance Testing

#### 1. Large File Handling
- [ ] Files over 100MB can be uploaded
- [ ] Files over 100MB can be downloaded
- [ ] Large files don't cause app to crash
- [ ] Upload progress is acceptable

#### 2. Many Files
- [ ] Directories with 100+ files load correctly
- [ ] Performance is acceptable with many files
- [ ] Selecting multiple files doesn't lag

#### 3. Concurrent Operations
- [ ] Multiple browsers can connect simultaneously
- [ ] Multiple file operations can run concurrently
- [ ] Logs are recorded for all clients

### Security Testing

#### 1. Path Traversal
- [ ] Cannot access files outside storage directory
- [ ] "../" in paths is handled safely
- [ ] Absolute paths are rejected

#### 2. CORS
- [ ] CORS headers allow web interface to work
- [ ] API endpoints are accessible from browser

## Automated Testing

Currently, this project does not include automated tests. To add them:

### Unit Tests

Create test files in `test/` directory:

```bash
flutter test
```

### Integration Tests

Create integration tests in `integration_test/` directory:

```bash
flutter test integration_test
```

## Test Environment

### Recommended Test Setup

1. **Device**: Physical Android 14+ device (not emulator) for full permission testing
2. **Network**: Local WiFi network with device-to-device communication enabled
3. **Test Computer**: Computer on same network for web interface testing
4. **Test Files**: 
   - Small text files (< 1KB)
   - Medium images (1-10MB)
   - Large videos (>100MB)
   - Various file types (PDF, DOC, ZIP, etc.)

### Test Data

Prepare test files in various sizes:
- `test-small.txt` (1KB)
- `test-medium.jpg` (5MB)
- `test-large.mp4` (100MB)
- `test-document.pdf` (2MB)
- `test-archive.zip` (50MB)

## Reporting Issues

When reporting bugs, include:

1. Android version
2. Device model
3. Steps to reproduce
4. Expected behavior
5. Actual behavior
6. Screenshots or logs
7. Flutter version (`flutter --version`)

## Test Results Template

```
Date: YYYY-MM-DD
Tester: [Name]
Device: [Model]
Android Version: [Version]
App Version: [Version]

Test Results:
- App Functionality: [ ] Pass [ ] Fail
- Server Start/Stop: [ ] Pass [ ] Fail
- Logging: [ ] Pass [ ] Fail
- Web Interface: [ ] Pass [ ] Fail
- File Operations: [ ] Pass [ ] Fail
- Error Handling: [ ] Pass [ ] Fail
- Performance: [ ] Pass [ ] Fail

Issues Found:
1. [Issue description]
2. [Issue description]

Notes:
[Additional comments]
```
