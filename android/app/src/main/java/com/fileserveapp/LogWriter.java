package com.fileserveapp;

import android.util.Log;
import java.io.*;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

public class LogWriter {
    private static final String TAG = "LogWriter";
    private File logDir;
    private SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault());
    private SimpleDateFormat fileFormat = new SimpleDateFormat("yyyyMMdd", Locale.getDefault());

    public LogWriter(File baseDir) {
        logDir = new File(baseDir, "logs");
        if (!logDir.exists()) {
            logDir.mkdirs();
        }
    }

    public synchronized void log(String level, String ip, String operation, String details) {
        try {
            String timestamp = dateFormat.format(new Date());
            String logFileName = "file-server-" + fileFormat.format(new Date()) + ".log";
            File logFile = new File(logDir, logFileName);
            
            String logEntry = String.format("[%s] %s | IP: %s | OP: %s | %s%n",
                    timestamp, level, ip, operation, details);
            
            // Append to file
            try (FileWriter fw = new FileWriter(logFile, true);
                 BufferedWriter bw = new BufferedWriter(fw)) {
                bw.write(logEntry);
            }
            
            Log.d(TAG, logEntry);
        } catch (IOException e) {
            Log.e(TAG, "Error writing log", e);
        }
    }

    public File getLogDir() {
        return logDir;
    }
}
