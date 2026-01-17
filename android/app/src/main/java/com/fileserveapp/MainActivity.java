package com.fileserveapp;

import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
import android.widget.Button;
import android.widget.TextView;
import android.widget.ScrollView;
import android.widget.LinearLayout;
import java.io.File;
import java.io.BufferedReader;
import java.io.FileReader;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

public class MainActivity extends AppCompatActivity {
    private Button startButton;
    private Button stopButton;
    private TextView statusText;
    private TextView logText;
    private ScrollView logScroll;
    private Intent serviceIntent;
    private boolean isRunning = false;
    private SimpleDateFormat dateFormat = new SimpleDateFormat("yyyyMMdd", Locale.getDefault());

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        
        startButton = findViewById(R.id.startButton);
        stopButton = findViewById(R.id.stopButton);
        statusText = findViewById(R.id.statusText);
        logText = findViewById(R.id.logText);
        logScroll = findViewById(R.id.logScroll);
        
        serviceIntent = new Intent(this, FileServerService.class);
        
        startButton.setOnClickListener(v -> startFileServer());
        stopButton.setOnClickListener(v -> stopFileServer());
        
        // 初始化檔案目錄
        initializeFileDirectories();
        
        // 加載今天的日誌
        loadLogs();
    }

    private void startFileServer() {
        if (!isRunning) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(serviceIntent);
            } else {
                startService(serviceIntent);
            }
            isRunning = true;
            statusText.setText("狀態: 執行中... 127.0.0.1:8080");
            statusText.setTextColor(getResources().getColor(android.R.color.holo_green_dark));
            startButton.setEnabled(false);
            stopButton.setEnabled(true);
        }
    }

    private void stopFileServer() {
        if (isRunning) {
            stopService(serviceIntent);
            isRunning = false;
            statusText.setText("狀態: 已停止");
            statusText.setTextColor(getResources().getColor(android.R.color.holo_red_dark));
            startButton.setEnabled(true);
            stopButton.setEnabled(false);
        }
    }

    private void initializeFileDirectories() {
        File filesDir = new File(getFilesDir(), "files");
        File wwwDir = new File(getFilesDir(), "www");
        File logsDir = new File(getFilesDir(), "logs");
        
        if (!filesDir.exists()) filesDir.mkdirs();
        if (!wwwDir.exists()) wwwDir.mkdirs();
        if (!logsDir.exists()) logsDir.mkdirs();
    }

    private void loadLogs() {
        new Thread(() -> {
            try {
                String logFileName = "file-server-" + dateFormat.format(new Date()) + ".log";
                File logFile = new File(getFilesDir(), "logs/" + logFileName);
                
                if (logFile.exists()) {
                    StringBuilder content = new StringBuilder();
                    try (BufferedReader reader = new BufferedReader(new FileReader(logFile))) {
                        String line;
                        while ((line = reader.readLine()) != null) {
                            content.insert(0, line + "\n");
                        }
                    }
                    
                    runOnUiThread(() -> logText.setText(content.toString()));
                } else {
                    runOnUiThread(() -> logText.setText("暫無日誌"));
                }
            } catch (Exception e) {
                runOnUiThread(() -> logText.setText("錯誤: " + e.getMessage()));
            }
        }).start();
    }
}
