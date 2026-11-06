package com.trackmylibrary.app

import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.trackmylibrary.app/drive_backup"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "backupToGoogleDriveOnly") {
                val filePath = call.argument<String>("filePath")
                val fileName = call.argument<String>("fileName") ?: "TrackMyLibrary_Master_Backup.xls"
                val targetEmail = call.argument<String>("targetEmail") ?: ""
                val mimeType = call.argument<String>("mimeType") ?: "application/vnd.ms-excel"

                if (filePath == null) {
                    result.error("ARG_ERROR", "filePath is required", null)
                    return@setMethodCallHandler
                }

                try {
                    val file = File(filePath)
                    val uri: Uri = try {
                        FileProvider.getUriForFile(this, "${applicationContext.packageName}.flutter.share_provider", file)
                    } catch (e1: Exception) {
                        try {
                            FileProvider.getUriForFile(this, "${applicationContext.packageName}.fileprovider", file)
                        } catch (e2: Exception) {
                            Uri.fromFile(file)
                        }
                    }

                    // Strictly restrict Intent to Google Drive package (com.google.android.apps.docs).
                    // This prevents arbitrary apps (WhatsApp, Bluetooth, etc.) from intercepting disaster recovery backups.
                    val driveIntent = Intent(Intent.ACTION_SEND).apply {
                        type = mimeType
                        setPackage("com.google.android.apps.docs")
                        putExtra(Intent.EXTRA_STREAM, uri)
                        putExtra(Intent.EXTRA_TITLE, fileName)
                        putExtra(Intent.EXTRA_SUBJECT, "Master Backup strictly bound to $targetEmail")
                        putExtra("account_name", targetEmail)
                        putExtra("authAccount", targetEmail)
                        putExtra("android.intent.extra.EMAIL", arrayOf(targetEmail))
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }

                    val pm = packageManager
                    val activities = pm.queryIntentActivities(driveIntent, 0)
                    if (activities.isNotEmpty()) {
                        startActivity(driveIntent)
                        result.success(true)
                    } else {
                        // Google Drive app is not installed on device
                        result.success(false)
                    }
                } catch (e: Exception) {
                    result.error("DRIVE_ERROR", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
