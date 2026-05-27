package com.example.frontend

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.frontend/storage"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    // Retorna la ruta absoluta del directorio Documents público
                    // Ej: /storage/emulated/0/Documents
                    "getDocumentsPath" -> {
                        val dir = Environment.getExternalStoragePublicDirectory(
                            Environment.DIRECTORY_DOCUMENTS
                        )
                        result.success(dir.absolutePath)
                    }

                    // true si ya tiene permiso MANAGE_EXTERNAL_STORAGE (Android 11+)
                    // o si está en Android 10 o menor (siempre true)
                    "hasAllFilesPermission" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                            result.success(Environment.isExternalStorageManager())
                        } else {
                            result.success(true)
                        }
                    }

                    // Abre la pantalla de Ajustes del sistema para que el usuario
                    // active "Acceso a todos los archivos" para esta app.
                    // Solo hace algo en Android 11+ (API 30+).
                    "requestAllFilesPermission" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                            if (!Environment.isExternalStorageManager()) {
                                try {
                                    val intent = Intent(
                                        Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION
                                    )
                                    intent.data = Uri.parse("package:$packageName")
                                    startActivity(intent)
                                } catch (e: Exception) {
                                    // Fallback: abrir ajustes generales de la app
                                    val fallback = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                                    fallback.data = Uri.parse("package:$packageName")
                                    startActivity(fallback)
                                }
                            }
                        }
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
