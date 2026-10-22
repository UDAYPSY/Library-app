import glob
import os
import re

def patch_gradle_files():
    gradle_files = glob.glob('android/app/build.gradle*')
    print(f"Found gradle files to patch: {gradle_files}")
    for file_path in gradle_files:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        is_kts = file_path.endswith('.kts')
        
        # Update minSdk to 23 for Cloud Firestore compatibility
        if is_kts:
            content = re.sub(r'minSdk\s*=\s*.*', 'minSdk = 23', content)
        else:
            content = re.sub(r'minSdkVersion\s*=?\s*.*', 'minSdkVersion 23', content)

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
