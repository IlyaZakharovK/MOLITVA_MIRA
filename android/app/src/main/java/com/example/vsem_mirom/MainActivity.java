package com.example.vsem_mirom;

import android.os.Bundle;
import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import com.baseflow.permissionhandler.PermissionHandlerPlugin;

public class MainActivity extends FlutterActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // Убрали вызов FlutterDownloaderPlugin.init
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        // Явная регистрация permission_handler (если автоматическая не работает)
        flutterEngine.getPlugins().add(new PermissionHandlerPlugin());
        // flutter_downloader регистрируется автоматически, добавлять не нужно
    }
}