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
            if '<queries>' not in content and '</manifest>' in content:
                content = content.replace('</manifest>', queries_block)
            with open(path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Patched AndroidManifest at {path}")

if __name__ == '__main__':
    patch_gradle_files()
    patch_manifest()
