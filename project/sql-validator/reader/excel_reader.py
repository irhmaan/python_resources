import re
from pathlib import Path
from openpyxl import Workbook, load_workbook
from common import app_config
from common.app_config import get_master_columns,worksheet_to_remove,get_invalid_chars
from common.logger import setup_logger
from common.file_writer import FileWriter

from services.likely import SimilarColumn

class ExcelReader:

    excel_sheet = None
    def __init__(self, file_path: str):
        self.logger = setup_logger()

        self.file_path = Path(file_path)
        """The target Excel file path used for data extraction."""
        
        #* using config file to load the master columns.
        self.master_columns = get_master_columns()
        """The master column data configured in config.yml."""

        # self.user_info()
        self.tableNames = set()
        """Set to store table name from excel file."""

        self.result_fw = FileWriter('output/script_result.yml')
        """Output result file writer(fw)."""

        self.invalid_chars : dict[str,str] = get_invalid_chars()
        """List of invalid characters to check in table names."""

    def user_info(self):
        print("Checkiing for:\n")
        for e_col, e_type in self.master_columns.items():
            print(f"{e_col} '->' {e_type}")

    def read(self) -> None:
        """Read the excel file and log err if any"""
        try:
            self.logger.info(f"Reading Excel file. Path: {self.file_path}\n")

            workbook = load_workbook(self.file_path)
            # check the sheets names - sanity check
            # print(workbook.sheetnames)

            # sheet_name = "Table Name"

            # if unwanted excel sheets are present, we can remove  or filter them and create an updated excel
            sheet_to_removed = worksheet_to_remove()
            if sheet_to_removed:
                for sheet_name in sheet_to_removed:
                    if sheet_name in workbook.sheetnames:
                        worksheet = workbook[sheet_name]
                        workbook.remove(worksheet)

            # save workbook after removing the specified columns
            self.excel_sheet = workbook
            workbook.save("data/data_test.xlsx")

            self.validate_excel()
        except Exception as ex:
            self.logger.warning(f"Err reading file {self.file_path}. {ex}")


    def alphanumeric_key(self, item: str) -> list:
        '''
        Sort the table names using regex and return sorted names as a list.
        '''
        pattern = r'(\d+)'
        
        # 1. Split the single string item into chunks of text and digits
        split_text = re.split(pattern, item)
        
        # 2. Process all chunks for this specific item and return them as a list
        return [int(t) if t.isdigit() else t.lower() for t in split_text if t]
    

    def printTableNames(self):
        #TODO: remove or comment this later.
        if self.tableNames:
            for i, v in enumerate(self.tableNames):    
                self.logger.info(f'{i+1}   {v}') 

    def create_table_name_file(self, cleaned_workbook ):
        """Write the table names found in excel file to a text file in output directory.
        Also removes invalid chars present in table names.
        """
        for sheet in cleaned_workbook.worksheets: 
            # tables.add(sheet.title)
            if(sheet.title == 'Table Name'):
                for row in sheet.iter_rows(min_col=3,max_col=3,min_row=2,values_only=True):
                    self.tableNames.add(row[0])

        self.tableNames_list : list[str] = sorted(self.tableNames, key=self.alphanumeric_key)
        table_name_file = FileWriter('output/tables.txt')            
        table_name_file.clear_content()

        for name in self.tableNames_list:
            #TODO: add invalid char replacement logic for other chars as well
            for char in self.invalid_chars.keys():
                if name.__contains__(char):
                    # print(f"Found & in Table name : {name} - replace with 'And'")
                    replacement_var = self.invalid_chars.get(char)
                    self.logger.warning(f"Found {char} in Table name : {name} - replace with '{replacement_var}'")

                    if replacement_var is not None:
                        name = name.replace(char, replacement_var)
            table_name_file.write_file(name)

        self.logger.info(f'Output file: {table_name_file.file_path}', )

    # def iterate_and_save_table_names(self, cleaned_workbook: Workbook):


    def validate_excel(self):
        """ Given an excel file, it checks the following\n:
                1. Reads table column_name and column_dtype.
                2. Using master_columns data, perform checking for - missing, expected columns & dtypes. Writes the result to a file in output directory.
        """
        cleaned_workbook  = self.excel_sheet
        """store missing columns"""
        missing_columns = []

        """store mis-match data type """
        wrong_types = []

        worksheet_schema = {}

        # loop through the sheets found.
        # print(f'\n ========= Tables ===========')
        #! Clear existing content of result file
        self.result_fw.clear_content()

        #! From our excel file , get and save the table names. Raise Err if workbook not loaded.
        if cleaned_workbook is None:
            raise ValueError("No workbook loaded")

        # for sheet in cleaned_workbook.worksheets: 
        #     # tables.add(sheet.title)
        #     if(sheet.title == 'Table Name'):
        #         for row in sheet.iter_rows(min_col=3,max_col=3,min_row=2,values_only=True):
        #             self.tableNames.add(row[0])

        # self.printTableNames()
        self.create_table_name_file(cleaned_workbook=cleaned_workbook)

        for sheet in cleaned_workbook.worksheets: # pyright: ignore[reportOptionalMemberAccess]

            sheet_title = sheet.title
            # Initialize schema for this sheet
            worksheet_schema[sheet_title] = {}

            # Read columns A and B
            for row, dtype in sheet.iter_rows(
                min_col=1,
                max_col=2,
                values_only=True
            ):

                if row:
                    worksheet_schema[sheet_title][str(row).strip().lower()] = (
                        str(dtype).strip()
                    )
            # store missing columns
            missing_columns = []
            # store mis-match data type
            wrong_types = []

            # get current sheet and store it in sheet_schema
            sheet_schema = worksheet_schema[sheet_title]
            # print(sheet_schema)

            # loop in using our master colmuns to get the expected col and type
            for e_col, e_type in self.master_columns.items():
                # get the data type stored in sheet.
                # need to use .lower() to avoid conflict in key mismatch

                actual_dtype = sheet_schema.get(e_col.lower())
                # print(e_col, actual_dtype, e_type)
                # print("SheetSchema\n", sheet_schema)

                # 1. Initialize variables to track the best match
                best_match = None
                highest_score = 0.0
                # add missing col if not found 
                if actual_dtype is None:
                    res = e_col
                    #TODO: Add logic to parse invalid chars in column_names and replace with "_".
                    #TODO: EX: Actuator_Max(Degree) => Actuator_Max_Degree
                    # Normalize keys and input to lowercase to fix the case-sensitivity issue
                    clean_input = e_col.lower().strip()
                    clean_keys = [k.lower().strip() for k in sheet_schema.keys()]

                    # get similar columns
                    matches = SimilarColumn().getSimilarColumn(sourceWord=clean_input, possibilities=clean_keys)
                    # print(matches)
                    if not matches:
                        res = f"{e_col} '->' {matches}"
                        missing_columns.append(f"{e_col} '->' {matches}")
                    else:
                        res = f"{e_col} '->'{matches}"
                        missing_columns.append(res)
                    continue
                
                # check and add if data type mis match.
                if actual_dtype != e_type.lower():
                    wrong_types.append(
                        (e_col, e_type, actual_dtype)
                    )

            if( sheet_title  == 'Table Name'):
                continue
            # print(f"\n=== Worksheet: {sheet_title} ===")
            self.result_fw.write_file(f"Worksheet: {sheet_title}")
            if missing_columns:
                self.result_fw.write_file(f"    Missing columns:")
                # print("Missing columns:")
                for col in missing_columns:
                    self.result_fw.write_file(f"     - {col}")
                    # print(f"  - {col}")

            if wrong_types:
                # print("Type mismatches:")
                self.result_fw.write_file("    Type mismatches:")
                for col, expected, actual in wrong_types:
                    self.result_fw.write_file(f"     - {col}: expected {expected}, found {actual}")
                    # print(
                    #     f"  - {col}: expected {expected}, found {actual}"
                    # )

            if not missing_columns and not wrong_types:
                self.result_fw.write_file("OK. Schema validation passed.")
                
                print("OK. Schema validation passed.")

        self.logger.info(f'Output file: {self.result_fw.file_path}', )
        # return missing_columns, wrong_types

