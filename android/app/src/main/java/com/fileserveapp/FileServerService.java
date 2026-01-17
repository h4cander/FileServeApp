package com.fileserveapp;

import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.os.IBinder;
import android.util.Log;
import java.io.File;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

public class FileServerService extends Service {
    private static final String TAG = "FileServerService";
    private FileServerThread serverThread;
    private LogWriter logWriter;

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        Log.d(TAG, "File Server Service started");
        
        // 初始化日誌
        logWriter = new LogWriter(getFilesDir());
        
        // 啟動服務器線程
        if (serverThread == null || !serverThread.isServerAlive()) {
            serverThread = new FileServerThread(getFilesDir(), logWriter);
            serverThread.start();
            logWriter.log("INFO", "127.0.0.1", "SERVICE_START", "File server started on port 8080");
        }
        
        return START_STICKY;
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        if (serverThread != null) {
            serverThread.stopServer();
            logWriter.log("INFO", "127.0.0.1", "SERVICE_STOP", "File server stopped");
        }
        Log.d(TAG, "File Server Service destroyed");
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }
}
