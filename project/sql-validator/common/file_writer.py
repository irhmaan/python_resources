from pathlib import Path


class FileWriter:
    """Utility class to create text or SQL files."""

    SUPPORTED_EXTENSIONS = {".txt", ".sql"}

    def __init__(self, filename: str):
        self.file_path = Path(filename)
        self.filename = filename

        if self.file_path.suffix.lower() not in self.SUPPORTED_EXTENSIONS:
            raise ValueError(
                f"Unsupported file type. Supported types: {', '.join(self.SUPPORTED_EXTENSIONS)}"
            )
        self.file_path.touch(exist_ok=True)

    def clear_content(self):
        with open(self.filename, 'r+', encoding='utf-8') as f:
            f.seek(0)
            f.truncate()

    def write_file(self, content: str = ""):
        """
        Write to the file with the provided content.

        Args:
            content (str): Content to write into the file.

        Returns:
            str: Absolute path of the created file.
        """
        with open(self.filename, "a", encoding="utf-8") as f:
            f.write(content + "\n")