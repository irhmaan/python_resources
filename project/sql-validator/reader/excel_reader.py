from pathlib import Path
from openpyxl import load_workbook

from models.table import TableDefinition

class ExcelReader:
    def __init__(self, file_path: str):
        self.file_path = Path(file_path)

    def read(self):
        # get the complete exel file or workbook
        workbook = load_workbook(self.file_path)
        # check the sheets names - sanity check
        print(workbook.sheetnames)

        sheet_name = "Table Name"
        if sheet_name in workbook.sheetnames:
            worksheet = workbook[sheet_name]
            workbook.remove(worksheet)

        workbook.save("data/data_test.xlsx")
        for sheet in workbook.worksheets:
            print(sheet)

        sheet = workbook.active
        if sheet is None:
            raise ValueError(f"No active worksheet found in {self.file_path}")

        rows = list(sheet.iter_rows(values_only=True))
        headers = rows[0]

        print(headers)
        if not rows:
            return []

        headers = rows[0]
        tables = []

        # for row in rows[1:]:
        #     data = dict(zip(headers, row))
            
        #     tables.append(
        #         TableDefinition(
        #             book=str(data["Book"] or ""),
        #             table_name=str(data["Table"] or ""),
        #             sql=str(data["SQL"] or ""),
        #         )
        #     )

        # return tables