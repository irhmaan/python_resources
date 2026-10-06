from common.load_config import app_config
from common.logger import setup_logger

logger = setup_logger()


class AppConfig:
    ENABLE_LOGS: bool
    MASTER_COLUMNS: dict[str, str]
    EXCEL_FILE_PATH: str
    SQL_FILE_PATH: str
    WORKSHEET_TO_REMOVE: list[str] | None
    INVALID_CHARACTERS: dict[str, str]
    ENCODING_SCHEMES: list[str]
    TEMPLATE_1_PATH: str
    TEMPLATE_2_PATH: str
    _initialized = False

    @classmethod
    def initialize(cls) -> None:
        if cls._initialized:
            return
        if not app_config:
            raise RuntimeError("App config not loaded. Call load_config.init() first.")

        cls.ENABLE_LOGS = app_config["enable_log"]
        cls.MASTER_COLUMNS = app_config["master_columns"]
        cls.EXCEL_FILE_PATH = app_config["excel_file_path"]
        cls.SQL_FILE_PATH = app_config["sql_file_path"]
        cls.WORKSHEET_TO_REMOVE = app_config.get("worksheet_to_remove")
        cls.INVALID_CHARACTERS = app_config["invalid_charaters"]
        cls.ENCODING_SCHEMES = app_config["encodings_schemes"]
        cls.TEMPLATE_1_PATH = app_config["template_1_path"]
        cls.TEMPLATE_2_PATH = app_config["template_2_path"]
        cls._initialized = True

    @classmethod
    def enable_log(cls) -> bool:
        cls.initialize()
        return cls.ENABLE_LOGS

    @classmethod
    def get_master_columns(cls) -> dict[str, str]:
        cls.initialize()
        return cls.MASTER_COLUMNS

    @classmethod
    def get_Excelfile_path(cls) -> str:
        '''
        Get the Excel file path for validating from app_config.yml.
        '''
        cls.initialize()
        return cls.EXCEL_FILE_PATH

    @classmethod
    def get_sqlfile_path(cls) -> str:
        '''
        Get the SQL file path for validating from app_config.yml.
        '''
        cls.initialize()
        return cls.SQL_FILE_PATH

    @classmethod
    def worksheet_to_remove(cls) -> list[str] | None:
        '''
        Use this to remove unwanted worksheet if present in excel workbook.
        Specify the names in config.yml if any.
        '''
        cls.initialize()
        worksheet = cls.WORKSHEET_TO_REMOVE
        if worksheet:
            logger.info(f"Worksheet configured to be removed from workbook: {worksheet}")
        else:
            logger.info("No worksheet configured to be removed from workbook.")
        return worksheet

    @classmethod
    def get_invalid_chars(cls) -> dict[str, str]:
        '''
        Use this to remove unwanted worksheet if present in excel workbook.
        Specify the names in config.yml if any.
        '''
        cls.initialize()
        invalid_chars = cls.INVALID_CHARACTERS
        if invalid_chars:
            logger.info(f"Invalid characters: {invalid_chars}")
        else:
            logger.info("No invalid characters found in config.yml.")
        return invalid_chars

    @classmethod
    def get_encoding_schemes(cls) -> list[str]:
        """
        Contains a list of encodings to try reading a sql file
        """
        cls.initialize()
        encoding_scheme = cls.ENCODING_SCHEMES
        if encoding_scheme:
            logger.info(f"Encodings: {encoding_scheme}")
        else:
            logger.info("No encoding scheme found. Specify compatible schemes in config.yml.")
        return encoding_scheme

    @classmethod
    def get_template_1_path(cls) -> str:
        cls.initialize()
        return cls.TEMPLATE_1_PATH

    @classmethod
    def get_template_2_path(cls) -> str:
        cls.initialize()
        return cls.TEMPLATE_2_PATH