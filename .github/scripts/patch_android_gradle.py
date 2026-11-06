import glob
import os
import re

def patch_gradle_files():
    # 1. Update android/local.properties with flutter.minSdkVersion=23 if present or create it
    local_props = 'android/local.properties'
    try:
        os.makedirs(os.path.dirname(local_props), exist_ok=True)
        with open(local_props, 'a', encoding='utf-8') as f:
            f.write('\nflutter.minSdkVersion=23\n')
        print(f"Added flutter.minSdkVersion=23 to {local_props}")
    except Exception as e:
        print(f"Notice: could not update {local_props}: {e}")

    gradle_files = glob.glob('android/app/build.gradle*')
    print(f"Found gradle files to patch: {gradle_files}")
    for file_path in gradle_files:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        is_kts = file_path.endswith('.kts')
        
        # Replace the entire line matching minSdk or minSdkVersion with clean minSdk = 23
        if is_kts:
            content = re.sub(r'^\s*.*minSdk.*$', '        minSdk = 23', content, flags=re.MULTILINE)
            content = re.sub(r'namespace\s*=\s*["\'][^"\']+["\']', 'namespace = "com.trackmylibrary.app"', content)
            content = re.sub(r'applicationId\s*=\s*["\'][^"\']+["\']', 'applicationId = "com.trackmylibrary.app"', content)

            kts_signing = '''    signingConfigs {
        getByName("debug") {
            storeFile = file("${project.projectDir}/release.jks")
            storePassword = "trackmylib2026"
            keyAlias = "trackmylib"
            keyPassword = "trackmylib2026"
        }
        create("release") {
            storeFile = file("${project.projectDir}/release.jks")
            storePassword = "trackmylib2026"
            keyAlias = "trackmylib"
            keyPassword = "trackmylib2026"
        }
    }'''
            if 'signingConfigs {' in content:
                content = re.sub(r'signingConfigs\s*\{.*?\n    \}', kts_signing, content, flags=re.DOTALL)
            content = re.sub(r'signingConfig\s*=\s*signingConfigs\.getByName\(["\']debug["\']\)', 'signingConfig = signingConfigs.getByName("release")', content)
        else:
            if re.search(r'minSdk\s*=', content):
                content = re.sub(r'^\s*.*minSdk.*$', '        minSdk = 23', content, flags=re.MULTILINE)
            else:
                content = re.sub(r'^\s*.*minSdk(Version)?.*$', '        minSdkVersion 23', content, flags=re.MULTILINE)
            content = re.sub(r'namespace\s+["\'][^"\']+["\']', 'namespace "com.trackmylibrary.app"', content)
            content = re.sub(r'namespace\s*=\s*["\'][^"\']+["\']', 'namespace = "com.trackmylibrary.app"', content)
            content = re.sub(r'applicationId\s+["\'][^"\']+["\']', 'applicationId "com.trackmylibrary.app"', content)
            content = re.sub(r'applicationId\s*=\s*["\'][^"\']+["\']', 'applicationId = "com.trackmylibrary.app"', content)

            # Override BOTH debug and release signing configs to permanently use release.jks
            groovy_signing = '''    signingConfigs {
        debug {
            storeFile file("${project.projectDir}/release.jks")
            storePassword 'trackmylib2026'
            keyAlias 'trackmylib'
            keyPassword 'trackmylib2026'
        }
        release {
            storeFile file("${project.projectDir}/release.jks")
            storePassword 'trackmylib2026'
            keyAlias 'trackmylib'
            keyPassword 'trackmylib2026'
        }
    }'''
            if 'signingConfigs {' in content:
                content = re.sub(r'signingConfigs\s*\{.*?\n    \}', groovy_signing, content, flags=re.DOTALL)
            else:
                content = content.replace('android {', f'android {{\n{groovy_signing}')
            
            # Switch any release signingConfig to release (with or without '=')
            content = re.sub(
                r'signingConfig\s*=?\s*signingConfigs\.\w+',
                'signingConfig signingConfigs.release',
                content
            )

        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Successfully patched {file_path}")

def patch_manifest():
    manifest_paths = ['android/app/src/main/AndroidManifest.xml']
    queries_block = """    <queries>
        <package android:name="com.google.android.apps.docs" />
        <package android:name="com.whatsapp" />
        <package android:name="com.whatsapp.w4b" />
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="https" />
        </intent>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="sms" />
        </intent>
        <intent>
            <action android:name="android.intent.action.SENDTO" />
            <data android:scheme="smsto" />
        </intent>
        <intent>
            <action android:name="android.intent.action.DIAL" />
            <data android:scheme="tel" />
        </intent>
    </queries>
</manifest>"""
    for path in manifest_paths:
        if os.path.exists(path):
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()
            # Ensure package attribute points to com.trackmylibrary.app if present
            content = re.sub(r'package\s*=\s*["\'][^"\']+["\']', 'package="com.trackmylibrary.app"', content)
            if 'android.permission.USE_BIOMETRIC' not in content:
                content = content.replace('<application', '<uses-permission android:name="android.permission.USE_BIOMETRIC"/>\n    <uses-permission android:name="android.permission.USE_FINGERPRINT"/>\n\n    <application')
            if '<queries>' not in content and '</manifest>' in content:
                content = content.replace('</manifest>', queries_block)
            elif 'com.google.android.apps.docs' not in content:
                content = content.replace('<queries>', '<queries>\n        <package android:name="com.google.android.apps.docs" />')
            with open(path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Patched AndroidManifest at {path}")

def patch_main_activity():
    activity_files = glob.glob('android/app/src/main/**/MainActivity.*', recursive=True)
    full_activity_code = '''package com.trackmylibrary.app

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
'''
    for file_path in activity_files:
        if file_path.endswith('.kt'):
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(full_activity_code)
            print(f"Injected full MainActivity with Google Drive MethodChannel at {file_path}")
        else:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            content = content.replace('import io.flutter.embedding.android.FlutterActivity', 'import io.flutter.embedding.android.FlutterFragmentActivity')
            content = content.replace(': FlutterActivity()', ': FlutterFragmentActivity()')
            content = content.replace('extends FlutterActivity', 'extends FlutterFragmentActivity')
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Patched {file_path} for FlutterFragmentActivity")


if __name__ == '__main__':
    patch_gradle_files()
    patch_manifest()
    patch_main_activity()
