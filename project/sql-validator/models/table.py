from dataclasses import dataclass

@dataclass
class TableDefinition:
    book: str
    table_name: str
    sql: str