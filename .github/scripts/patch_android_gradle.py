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
        else:
            if re.search(r'minSdk\s*=', content):
                content = re.sub(r'^\s*.*minSdk.*$', '        minSdk = 23', content, flags=re.MULTILINE)
            else:
                content = re.sub(r'^\s*.*minSdk(Version)?.*$', '        minSdkVersion 23', content, flags=re.MULTILINE)

        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Successfully patched {file_path}")

    # Print out patched file for verification in CI logs
    for file_path in gradle_files:
        print(f"\n=== Content of {file_path} ===")
        with open(file_path, 'r', encoding='utf-8') as f:
            print(f.read())

if __name__ == '__main__':
    patch_gradle_files()
