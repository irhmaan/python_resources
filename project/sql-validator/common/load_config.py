import yaml
from pathlib import Path
from common.logger import setup_logger
import os
import sys

app_config = {}
CONFIG = {}

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
    with open(config_path, "r", encoding="utf-8") as cfile:
        CONFIG = yaml.safe_load(cfile)
        logger.info("config file loaded.")

        if CONFIG:
            app_config.update(CONFIG)
        else:
            logger.error('config.yml empty, please check.')

# def enable_log() -> bool:
#     '''
#     if true log file will be created.
#     '''
#     if CONFIG is None:
#         logger.info("enable_log key not found.")
#         raise RuntimeError(
#             'enable_log not defined in config.yml'
#         )
#     return app_config['enable_log']

# def get_master_columns() -> dict:
#     if CONFIG is None:
#         logger.info("master column config missing in config.yml")
#         raise RuntimeError(
#             "master_columns not loaded. Call load_config() first."
#         )
#     return app_config['master_columns']

# def  get_Excelfile_path() -> str:
#     '''
#     Get the Excel file path for validating from config.yml.
#     '''
#     if CONFIG is None:
#         logger.info("excel file path not defined in config.yml")
#         raise RuntimeError(
#             'excel file path not defined in config.yml'
#         )
#     return app_config['excel_file_path']
