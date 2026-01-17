package com.fileserveapp;

import android.util.Log;
import fi.iki.elonen.NanoHTTPD;
import java.io.*;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.text.SimpleDateFormat;
import java.util.*;

public class FileServerThread extends Thread {
    private static final String TAG = "FileServerThread";
    private static final int PORT = 8080;
    private AndroidHttpServer server;
    private File baseDir;
    private LogWriter logWriter;
    private volatile boolean running = false;

    public FileServerThread(File baseDir, LogWriter logWriter) {
        this.baseDir = baseDir;
        this.logWriter = logWriter;
        this.setName("FileServerThread");
    }

    @Override
    public void run() {
        try {
            server = new AndroidHttpServer(PORT);
            server.start(NanoHTTPD.SOCKET_READ_TIMEOUT, false);
            running = true;
            Log.d(TAG, "File Server started on port " + PORT);
            
            while (running) {
                Thread.sleep(1000);
            }
        } catch (IOException | InterruptedException e) {
            Log.e(TAG, "Error starting file server", e);
        } finally {
            if (server != null) {
                server.stop();
            }
        }
    }

    public void stopServer() {
        running = false;
        if (server != null) {
            server.stop();
        }
    }

    public boolean isServerAlive() {
        return running && server != null && server.isAlive();
    }

    private class AndroidHttpServer extends NanoHTTPD {
        public AndroidHttpServer(int port) {
            super(port);
        }

        @Override
        public Response serve(IHTTPSession session) {
            String uri = session.getUri();
            Method method = session.getMethod();

            try {
                if (uri.equals("/") || !uri.startsWith("/api/")) {
                    return serveStaticFile(uri);
                } else if (uri.equals("/api/list")) {
                    return handleList(session);
                } else if (uri.equals("/api/get")) {
                    return handleGet(session);
                } else if (uri.equals("/api/upload") && method == Method.POST) {
                    return handleUpload(session);
                } else if (uri.equals("/api/delete")) {
                    return handleDelete(session);
                } else if (uri.equals("/api/rename") && method == Method.POST) {
                    return handleRename(session);
                } else if (uri.equals("/api/logs")) {
                    return handleLogs(session);
                }
                return newFixedLengthResponse(Response.Status.NOT_FOUND, NanoHTTPD.MIME_PLAINTEXT, "Not Found");
            } catch (Exception e) {
                Log.e(TAG, "Error handling request: " + uri, e);
                return newFixedLengthResponse(Response.Status.INTERNAL_ERROR, NanoHTTPD.MIME_PLAINTEXT, "Internal Error");
            }
        }

        private Response serveStaticFile(String uri) {
            if (uri.equals("/")) uri = "/index.html";
            File file = new File(baseDir, "www" + uri);
            if (file.exists() && file.isFile()) {
                try {
                    return newChunkedResponse(Response.Status.OK, getMimeType(file.getName()), new FileInputStream(file));
                } catch (FileNotFoundException e) {
                    return newFixedLengthResponse(Response.Status.NOT_FOUND, NanoHTTPD.MIME_PLAINTEXT, "Not Found");
                }
            }
            return newFixedLengthResponse(Response.Status.NOT_FOUND, NanoHTTPD.MIME_PLAINTEXT, "Not found");
        }

        private Response handleList(IHTTPSession session) {
            Map<String, String> params = session.getParms();
            String path = params.get("path");
            if (path == null) path = "";
            
            File dir = new File(baseDir, "files/" + path);
            StringBuilder response = new StringBuilder("[");
            
            if (dir.exists() && dir.isDirectory()) {
                File[] files = dir.listFiles();
                if (files != null) {
                    for (int i = 0; i < files.length; i++) {
                        File f = files[i];
                        if (i > 0) response.append(",");
                        response.append(String.format(
                            "{\"name\":\"%s\",\"isDir\":%b,\"size\":%d,\"modified\":%d}",
                            f.getName(), f.isDirectory(), f.length(), f.lastModified()
                        ));
                    }
                }
            }
            response.append("]");
            logWriter.log("INFO", session.getRemoteIpAddress(), "LIST", path);
            return newJsonResponse(response.toString());
        }

        private Response handleGet(IHTTPSession session) {
            Map<String, String> params = session.getParms();
            String path = params.get("path");
            if (path == null) path = "";
            
            File file = new File(baseDir, "files/" + path);
            if (file.exists() && file.isFile()) {
                try {
                    Response res = newChunkedResponse(Response.Status.OK, getMimeType(file.getName()), new FileInputStream(file));
                    res.addHeader("Content-Disposition", "attachment; filename=\"" + file.getName() + "\"");
                    logWriter.log("INFO", session.getRemoteIpAddress(), "GET", path);
                    return res;
                } catch (FileNotFoundException e) {
                    return newFixedLengthResponse(Response.Status.NOT_FOUND, NanoHTTPD.MIME_PLAINTEXT, "Not Found");
                }
            }
            return newFixedLengthResponse(Response.Status.NOT_FOUND, NanoHTTPD.MIME_PLAINTEXT, "Not found");
        }

        private Response handleUpload(IHTTPSession session) throws IOException, ResponseException {
            Map<String, String> headers = session.getHeaders();
            String path = headers.get("x-file-path");
            if (path == null) path = "";
            
            String filename = headers.get("x-file-name");
            if (filename == null) filename = "uploaded_file";

            Map<String, String> files = new HashMap<>();
            session.parseBody(files);
            
            String tmpPath = files.get("content");
            if (tmpPath != null) {
                File tmpFile = new File(tmpPath);
                File targetFile = new File(new File(baseDir, "files/" + path), filename);
                targetFile.getParentFile().mkdirs();
                if (targetFile.exists()) targetFile.delete();
                tmpFile.renameTo(targetFile);
            }
            
            logWriter.log("INFO", session.getRemoteIpAddress(), "UPLOAD", path + "/" + filename);
            return newJsonResponse("{\"success\":true}");
        }

        private Response handleDelete(IHTTPSession session) {
            Map<String, String> params = session.getParms();
            String path = params.get("path");
            if (path == null) path = "";
            
            File file = new File(baseDir, "files/" + path);
            boolean success = false;
            if (file.exists()) {
                success = deleteRecursive(file);
            }
            logWriter.log("INFO", session.getRemoteIpAddress(), "DELETE", path);
            return newJsonResponse("{\"success\":" + success + "}");
        }

        private Response handleRename(IHTTPSession session) throws IOException, ResponseException {
            Map<String, String> files = new HashMap<>();
            session.parseBody(files);
            String postData = files.get("postData");
            
            String oldPath = extractJsonValue(postData, "oldPath");
            String newName = extractJsonValue(postData, "newName");
            
            File oldFile = new File(baseDir, "files/" + oldPath);
            File newFile = new File(oldFile.getParent(), newName);
            
            boolean success = false;
            if (oldFile.exists()) {
                success = oldFile.renameTo(newFile);
            }
            logWriter.log("INFO", session.getRemoteIpAddress(), "RENAME", oldPath + " -> " + newName);
            return newJsonResponse("{\"success\":" + success + "}");
        }

        private Response handleLogs(IHTTPSession session) {
            Map<String, String> params = session.getParms();
            String date = params.get("date");
            if (date == null || date.isEmpty()) {
                date = new SimpleDateFormat("yyyyMMdd").format(new Date());
            }
            
            File logFile = new File(logWriter.getLogDir(), "file-server-" + date + ".log");
            String response = "[]";
            if (logFile.exists()) {
                try {
                    response = new String(Files.readAllBytes(logFile.toPath()));
                } catch (IOException e) {}
            }
            return newJsonResponse(response);
        }

        private Response newJsonResponse(String json) {
            Response res = newFixedLengthResponse(Response.Status.OK, "application/json; charset=utf-8", json);
            res.addHeader("Access-Control-Allow-Origin", "*");
            return res;
        }

        private String getMimeType(String filename) {
            if (filename.endsWith(".html")) return "text/html";
            if (filename.endsWith(".js")) return "application/javascript";
            if (filename.endsWith(".css")) return "text/css";
            if (filename.endsWith(".json")) return "application/json";
            if (filename.endsWith(".png")) return "image/png";
            if (filename.endsWith(".jpg") || filename.endsWith(".jpeg")) return "image/jpeg";
            return "application/octet-stream";
        }

        private boolean deleteRecursive(File file) {
            if (file.isDirectory()) {
                File[] children = file.listFiles();
                if (children != null) {
                    for (File child : children) deleteRecursive(child);
                }
            }
            return file.delete();
        }

        private String extractJsonValue(String json, String key) {
            if (json == null) return "";
            String search = "\"" + key + "\":\"";
            int start = json.indexOf(search);
            if (start == -1) return "";
            start += search.length();
            int end = json.indexOf("\"", start);
            if (end == -1) return "";
            return json.substring(start, end);
        }
    }
}
