package com.trackmylibrary.app

import android.content.ClipData
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
                    if (!file.exists()) {
                        result.error("FILE_NOT_FOUND", "File not found at $filePath", null)
                        return@setMethodCallHandler
                    }

                    // Copy to cacheDir/share_plus to guarantee FileProvider authority compatibility
                    val shareDir = File(cacheDir, "share_plus")
                    if (!shareDir.exists()) {
                        shareDir.mkdirs()
                    }
                    val shareFile = File(shareDir, fileName)
                    file.copyTo(shareFile, overwrite = true)

                    val uri: Uri = try {
                        FileProvider.getUriForFile(this, "${applicationContext.packageName}.flutter.share_provider", shareFile)
                    } catch (e1: Exception) {
                        try {
                            FileProvider.getUriForFile(this, "${applicationContext.packageName}.fileprovider", shareFile)
                        } catch (e2: Exception) {
                            Uri.fromFile(shareFile)
                        }
                    }

                    // Strictly route Intent to Google Drive app ("Save to Drive") with granted URI permissions
                    val driveIntent = Intent(Intent.ACTION_SEND).apply {
                        type = mimeType
                        setPackage("com.google.android.apps.docs")
                        putExtra(Intent.EXTRA_STREAM, uri)
                        putExtra(Intent.EXTRA_TITLE, fileName)
                        putExtra(Intent.EXTRA_SUBJECT, fileName)
                        if (targetEmail.isNotEmpty()) {
                            putExtra("account_name", targetEmail)
                            putExtra("authAccount", targetEmail)
                            putExtra("android.intent.extra.EMAIL", arrayOf(targetEmail))
                        }
                        clipData = ClipData.newRawUri(fileName, uri)
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }

                    val pm = packageManager
                    val activities = pm.queryIntentActivities(driveIntent, 0)
                    if (activities.isNotEmpty()) {
                        grantUriPermission("com.google.android.apps.docs", uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        startActivity(driveIntent)
                        result.success(true)
                    } else {
                        // Google Drive app is not installed or unable to handle directly; return false to trigger share sheet fallback
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
