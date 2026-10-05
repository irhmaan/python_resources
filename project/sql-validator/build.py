import os
import shutil
import subprocess

# 1. Run the PyInstaller command
print("Building executable...")
subprocess.run(["pyinstaller", "--onefile" ,"--name=Validator", "main.py"], check=True)

# 2. Define source and destination
source_file = "config.yml"
table_names_file = "Table_Names.txt"
source_data_dir = "data"
destination_dir = "dist"
output_dir = "output"
template_dir = "templates"


# 3. Copy the file if the build succeeded
if os.path.exists(destination_dir):
    print(f"Copying {source_file} to {destination_dir}...")
    shutil.copy(source_file, os.path.join(destination_dir, source_file))
    print(f"Copying {table_names_file} to {destination_dir}...")
    shutil.copy(table_names_file, os.path.join(destination_dir, table_names_file))
    print(f"Copying {source_data_dir} to {destination_dir}...")
    shutil.copytree(
        source_data_dir,
        os.path.join(destination_dir, source_data_dir),
        dirs_exist_ok=True,
    )
    print(f"Copying {template_dir} to {destination_dir}...")
    shutil.copytree(
            template_dir,
            os.path.join(destination_dir, template_dir),
            dirs_exist_ok=True,
        )
    output_path = os.path.join(destination_dir, output_dir)
    os.makedirs(output_path, exist_ok=True)

    print("Build complete! Check the 'dist' folder.")
else:
    print("Build failed. 'dist' folder not found.")
