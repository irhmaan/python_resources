from common.load_config import app_config
from common.logger import setup_logger

logger = setup_logger()


def enable_log() -> bool:
    '''
    if true log file will be created.
    '''
    if app_config is None:
        logger.info("enable_log key not found.")
        raise RuntimeError(
            'enable_log not defined in app_config.yml'
        )
    return app_config['enable_log']

def get_master_columns() -> dict:
    if app_config is None:
        logger.info("master column app_config missing in app_config.yml")
        raise RuntimeError(
            "master_columns not loaded. Call load_app_config() first."
        )
    return app_config['master_columns']

def  get_Excelfile_path() -> str:
    '''
    Get the Excel file path for validating from app_config.yml.
    '''
    if app_config is None:
        logger.info("excel file path not defined in app_config.yml")
        raise RuntimeError(
            'excel file path not defined in app_config.yml'
        )
    return app_config['excel_file_path']
