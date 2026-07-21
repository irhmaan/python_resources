import yaml
from pathlib import Path
from common.logger import setup_logger
import os
import sys


CONFIG: dict | None = None
MASTER_COLUMNS: dict | None = None
Excel_File_Path: str | None = None

logger = setup_logger()

def get_config_path():
    """Returns the directory containing the running script or compiled .exe"""
    if getattr(sys, 'frozen', False):
        # Running as a compiled .exe
        # sys.executable points to: .../dist/your_program.exe
        # os.path.dirname gets: .../dist
        base_dir = os.path.dirname(sys.executable)
    else:
        # Running as .py script in project/validator/common/
        current_dir = os.path.dirname(os.path.abspath(__file__))
        # os.path.dirname() on the current dir moves you up to project/validator/
        base_dir = os.path.dirname(current_dir)

    return os.path.join(base_dir, "config.yml")



config_path = get_config_path()


def load_config() -> None:
    global CONFIG, MASTER_COLUMNS, Excel_File_Path

    with open(config_path, "r", encoding="utf-8") as cfile:
        CONFIG = yaml.safe_load(cfile)
        logger.info("config file loaded.")
        MASTER_COLUMNS = CONFIG["MASTER_COLUMNS"] # type: ignore
        logger.info("master columns loaded.")
        Excel_File_Path = CONFIG['excel_file_path'] # pyright: ignore[reportOptionalSubscript]
        logger.info("got excel path.")




def get_master_columns() -> dict:
    if MASTER_COLUMNS is None:
        logger.info("master column config missing in config.yml")
        raise RuntimeError(
            "MASTER_COLUMNS not loaded. Call load_config() first."
        )

    return MASTER_COLUMNS

def  get_Excelfile_path() -> str:
    '''
    Get the Excel file path for validating from config.yml.
    '''
    if Excel_File_Path is None:
        logger.info("excel file path not defined in config.yml")
        raise RuntimeError(
            'Excel file path not defined in config.yml'
        )
    return Excel_File_Path