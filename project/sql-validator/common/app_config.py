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

def  get_sqlfile_path() -> str:
    '''
    Get the SQL file path for validating from app_config.yml.
    '''
    if app_config is None:
        logger.info("sql file path not defined in app_config.yml")
        raise RuntimeError(
            'sql file path not defined in app_config.yml'
        )
    return app_config['sql_file_path']

def worksheet_to_remove()-> list[str]:
    '''
    Use this to remove unwanted worksheet if present in excel workbook.
    Specify the names in config.yml if any.
    '''
    worksheet = app_config['worksheet_to_remove']
    if app_config and worksheet:
        logger.info(f'woksheet configured to be removed from workbook. {worksheet}' )
    else:
        logger.info("No woksheet configured to be removed from workbook.")
    return worksheet

def get_invalid_chars():
    '''
    Use this to remove unwanted worksheet if present in excel workbook.
    Specify the names in config.yml if any.
    '''
    invalid_chars: dict[str, str] = app_config['invalid_charaters']
    if app_config and invalid_chars:
        logger.info(f'Invalid Characters. {invalid_chars}' )
    else:
        logger.info("No invalid_chars found in config.yml. Define If require to check for invalid chars in table/columns.")
    return invalid_chars

def get_encoding_schemes()-> list[str]:
    """
    Contains a list of encodings to try reading a sql file
    """
    encoding_scheme: list[str] = app_config["encodings_schemes"]
    if app_config and encoding_scheme:
            logger.info(f'Encodings. {encoding_scheme}' )
    else:
        logger.info("No encoding scheme found. Pls mention compatible schemes to read sql file.")
    return encoding_scheme