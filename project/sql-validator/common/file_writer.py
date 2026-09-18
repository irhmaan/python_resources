from pathlib import Path


class FileWriter:
    """
    Utility class to create text or SQL files.
    
    Args:
        Filename: Name of the file to be created.
        
    Note:
        If file not exists, it will be created.
    
    """

    SUPPORTED_EXTENSIONS = {".txt", ".sql"}

    def __init__(self, filename: str):
        self.file_path = Path(filename)
        self.filename = filename
        self.odir = Path('output/')

        if self.file_path.suffix.lower() not in self.SUPPORTED_EXTENSIONS:
            raise ValueError(
                f"Unsupported file type. Supported types: {', '.join(self.SUPPORTED_EXTENSIONS)}"
            )
        self.odir.mkdir(
            parents=True,exist_ok=True)   
        self.file_path.touch(exist_ok=True)

    def clear_content(self):
        '''
        clear the content of the current file opened.
        '''
        with open(self.filename, 'r+', encoding='utf-8') as f:
            f.seek(0)
            f.truncate()

    def write_file(self, content: str = ""):
        """
        Write to the file with the provided content.

        Args:
            content (str): Content to write into the file.
        """
        with open(self.filename, "a", encoding="utf-8") as f:
            f.write(content + "\n")