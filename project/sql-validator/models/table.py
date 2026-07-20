from dataclasses import dataclass
from datetime import datetime


@dataclass
class TableDefinition:
    book: str
    table_name: str
    sql: str
    
@dataclass
class ColumnDefinition:
    name: str
    data_type: type


MASTER_COLUMNS = {
    "RFID": "VARCHAR(50)",
    "DTS_PASS": "datetime",
    "DTS_SCAN": "datetime",
    "WORKORDER": "VARCHAR(50)",
    "MODEL_NO": "VARCHAR(50)",
    "CT": "float",
    "Status": "VARCHAR(50)",
    "CELLNO": "VARCHAR(50)",
    "FCS": "int",
    "FCA": "int",
    "Routing": "VARCHAR(50)",
    "Serial_No": "int",
    "DCode": "VARCHAR(50)",
    "ProfitCenterCode": "VARCHAR(50)",
    "MachineCode": "VARCHAR(50)",
    "OperationCode": "VARCHAR(50)",
    "TS_Flag": "smallint",
}