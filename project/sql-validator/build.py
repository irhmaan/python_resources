import os
import shutil
import subprocess

# 1. Run the PyInstaller command
print("Building executable...")
subprocess.run(["pyinstaller", "--onefile" ,"--name=Validator", "main.py"], check=True)

# 2. Define source and destination
source_file = "config.yml"
destination_dir = "dist"

# 3. Copy the file if the build succeeded
if os.path.exists(destination_dir):
    print(f"Copying {source_file} to {destination_dir}...")
    shutil.copy(source_file, os.path.join(destination_dir, source_file))
    print("Build complete! Check the 'dist' folder.")
else:
    print("Build failed. 'dist' folder not found.")
