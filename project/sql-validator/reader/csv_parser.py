import csv
from pathlib import Path
from models.table import TableDefinition

class CSVReader:
    
    #constructor
    def __init__(self, file_path: str):
        self.file_path = Path(file_path)

        def read(self):
            tables=[]

            with self.file_path.open(
                mode='r'
            ) as file:
                reader = csv.DictReader(file)

                for row in reader:
                    tables.append(TableDefinition(
                        book=row['Book'],
                        table_name=row['Table'],
                        sql=row['Sql']
                    )
                 )
            return tables
