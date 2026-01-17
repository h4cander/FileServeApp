package com.fileserveapp;

import android.util.Log;
import com.sun.net.httpserver.*;
import java.io.*;
import java.net.InetSocketAddress;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.*;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;

public class FileServerThread extends Thread {
    private static final String TAG = "FileServerThread";
    private static final int PORT = 8080;
    private HttpServer server;
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
            server = HttpServer.create(new InetSocketAddress(PORT), 0);
            running = true;
            
            // 靜態文件處理
            server.createContext("/", new StaticHandler());
            
            // API 端點
            server.createContext("/api/list", new ListHandler());
            server.createContext("/api/get", new GetHandler());
            server.createContext("/api/upload", new UploadHandler());
            server.createContext("/api/delete", new DeleteHandler());
            server.createContext("/api/rename", new RenameHandler());
            server.createContext("/api/logs", new LogsHandler());
            
            server.start();
            Log.d(TAG, "File Server started on port " + PORT);
        } catch (IOException e) {
            Log.e(TAG, "Error starting file server", e);
        }
    }

    public void stopServer() {
        running = false;
        if (server != null) {
            server.stop(0);
        }
    }

    public boolean isAlive() {
        return running && server != null;
    }

    // 靜態文件處理
    class StaticHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            String path = exchange.getRequestURI().getPath();
            
            if (path.equals("/") || path.equals("")) {
                path = "/index.html";
            }
            
            File file = new File(baseDir, "www" + path);
            if (file.exists() && file.isFile()) {
                exchange.getResponseHeaders().set("Content-Type", getMimeType(file));
                byte[] bytes = Files.readAllBytes(file.toPath());
                exchange.sendResponseHeaders(200, bytes.length);
                exchange.getResponseBody().write(bytes);
            } else {
                String response = "404 Not Found";
                exchange.sendResponseHeaders(404, response.length());
                exchange.getResponseBody().write(response.getBytes());
            }
            exchange.close();
        }
    }

    // 列出文件
    class ListHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            String path = exchange.getRequestURI().getQuery();
            if (path == null) path = "";
            path = URLDecoder.decode(path.replace("path=", ""), StandardCharsets.UTF_8);
            
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
            sendJson(exchange, response.toString());
            logWriter.log("INFO", getClientIp(exchange), "LIST", path);
        }
    }

    // 獲取文件
    class GetHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            String path = exchange.getRequestURI().getQuery();
            if (path == null) path = "";
            path = URLDecoder.decode(path.replace("path=", ""), StandardCharsets.UTF_8);
            
            File file = new File(baseDir, "files/" + path);
            if (file.exists() && file.isFile()) {
                exchange.getResponseHeaders().set("Content-Type", getMimeType(file));
                exchange.getResponseHeaders().set("Content-Disposition", 
                    "attachment; filename=\"" + file.getName() + "\"");
                byte[] bytes = Files.readAllBytes(file.toPath());
                exchange.sendResponseHeaders(200, bytes.length);
                exchange.getResponseBody().write(bytes);
                logWriter.log("INFO", getClientIp(exchange), "GET", path);
            } else {
                sendError(exchange, "File not found");
            }
            exchange.close();
        }
    }

    // 上傳文件
    class UploadHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            if ("POST".equals(exchange.getRequestMethod())) {
                String path = exchange.getRequestHeaders().getFirst("X-File-Path");
                if (path == null) path = "";
                path = URLDecoder.decode(path, StandardCharsets.UTF_8);
                
                File dir = new File(baseDir, "files/" + path);
                dir.mkdirs();
                
                String filename = exchange.getRequestHeaders().getFirst("X-File-Name");
                if (filename == null) filename = "uploaded_file";
                
                File file = new File(dir, filename);
                try (InputStream in = exchange.getRequestBody();
                     FileOutputStream out = new FileOutputStream(file)) {
                    byte[] buffer = new byte[4096];
                    int len;
                    while ((len = in.read(buffer)) != -1) {
                        out.write(buffer, 0, len);
                    }
                }
                
                sendJson(exchange, "{\"success\":true,\"path\":\"" + path + filename + "\"}");
                logWriter.log("INFO", getClientIp(exchange), "UPLOAD", path + filename);
            }
            exchange.close();
        }
    }

    // 刪除文件
    class DeleteHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            String path = exchange.getRequestURI().getQuery();
            if (path == null) path = "";
            path = URLDecoder.decode(path.replace("path=", ""), StandardCharsets.UTF_8);
            
            File file = new File(baseDir, "files/" + path);
            if (file.exists()) {
                boolean success = deleteRecursive(file);
                sendJson(exchange, "{\"success\":" + success + "}");
                logWriter.log("INFO", getClientIp(exchange), "DELETE", path);
            } else {
                sendError(exchange, "File not found");
            }
            exchange.close();
        }
    }

    // 重命名文件
    class RenameHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            if ("POST".equals(exchange.getRequestMethod())) {
                BufferedReader in = new BufferedReader(new InputStreamReader(exchange.getRequestBody()));
                StringBuilder body = new StringBuilder();
                String line;
                while ((line = in.readLine()) != null) {
                    body.append(line);
                }
                
                String oldPath = extractJsonValue(body.toString(), "oldPath");
                String newName = extractJsonValue(body.toString(), "newName");
                
                File oldFile = new File(baseDir, "files/" + oldPath);
                File newFile = new File(oldFile.getParent(), newName);
                
                if (oldFile.exists()) {
                    boolean success = oldFile.renameTo(newFile);
                    sendJson(exchange, "{\"success\":" + success + "}");
                    logWriter.log("INFO", getClientIp(exchange), "RENAME", oldPath + " -> " + newName);
                } else {
                    sendError(exchange, "File not found");
                }
            }
            exchange.close();
        }
    }

    // 日誌處理
    class LogsHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            String date = exchange.getRequestURI().getQuery();
            if (date == null || date.isEmpty()) {
                date = new java.text.SimpleDateFormat("yyyyMMdd").format(new Date());
            } else {
                date = date.replace("date=", "");
            }
            
            File logFile = new File(logWriter.getLogDir(), "file-server-" + date + ".log");
            String response;
            
            if (logFile.exists()) {
                response = new String(Files.readAllBytes(logFile.toPath()));
            } else {
                response = "[]";
            }
            
            sendJson(exchange, response);
            exchange.close();
        }
    }

    // 工具方法
    private void sendJson(HttpExchange exchange, String json) throws IOException {
        exchange.getResponseHeaders().set("Content-Type", "application/json; charset=utf-8");
        exchange.getResponseHeaders().set("Access-Control-Allow-Origin", "*");
        byte[] bytes = json.getBytes(StandardCharsets.UTF_8);
        exchange.sendResponseHeaders(200, bytes.length);
        exchange.getResponseBody().write(bytes);
        exchange.close();
    }

    private void sendError(HttpExchange exchange, String message) throws IOException {
        String json = "{\"error\":\"" + message + "\"}";
        byte[] bytes = json.getBytes(StandardCharsets.UTF_8);
        exchange.getResponseHeaders().set("Content-Type", "application/json; charset=utf-8");
        exchange.sendResponseHeaders(400, bytes.length);
        exchange.getResponseBody().write(bytes);
        exchange.close();
    }

    private String getMimeType(File file) {
        String name = file.getName();
        if (name.endsWith(".html")) return "text/html";
        if (name.endsWith(".js")) return "application/javascript";
        if (name.endsWith(".css")) return "text/css";
        if (name.endsWith(".json")) return "application/json";
        if (name.endsWith(".png")) return "image/png";
        if (name.endsWith(".jpg") || name.endsWith(".jpeg")) return "image/jpeg";
        if (name.endsWith(".gif")) return "image/gif";
        if (name.endsWith(".pdf")) return "application/pdf";
        return "application/octet-stream";
    }

    private String getClientIp(HttpExchange exchange) {
        String ip = exchange.getRequestHeaders().getFirst("X-Forwarded-For");
        if (ip == null || ip.isEmpty()) {
            ip = exchange.getRemoteAddress().getAddress().getHostAddress();
        }
        return ip;
    }

    private boolean deleteRecursive(File file) {
        if (file.isDirectory()) {
            File[] children = file.listFiles();
            if (children != null) {
                for (File child : children) {
                    deleteRecursive(child);
                }
            }
        }
        return file.delete();
    }

    private String extractJsonValue(String json, String key) {
        String search = "\"" + key + "\":\"";
        int start = json.indexOf(search);
        if (start == -1) return "";
        start += search.length();
        int end = json.indexOf("\"", start);
        return json.substring(start, end);
    }
}
