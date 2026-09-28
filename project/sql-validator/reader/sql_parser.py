import os

from common.logger import setup_logger
from common.app_config import get_sqlfile_path,get_master_columns
from pathlib import Path
import re
# import pandas as pd

class SqlParser:
    # load a sql file.
    # sanitize the file only need to extract create statements. encoding scheme should be utf-16.
    # create a temporary file with the sanitized file and then start checking it
    #

    def __init__(self) -> None:
        self.logger =  setup_logger(name='Sql Validator')
        self.sql_file_path = Path(get_sqlfile_path())
        self.master_columns = get_master_columns()
        self.txt_path  = Path("Table_Names.txt")
        self.table_name_list :  list[str]
        # self.load_table_names()
        self.extract_create_scripts_by_parsing()

    def load_table_names(self, ):
        """Reads table names from a text file."""
        if not os.path.exists(self.txt_path):
            raise FileNotFoundError(f"Table list file not found: {self.txt_path}")
        
        with open(self.txt_path, 'r', encoding='utf-8') as f:
            return [line.strip() for line in f if line.strip() and not line.startswith('#')]

    def extract_create_scripts_by_parsing(self):
        """
        Safely extracts CREATE TABLE blocks by tracking parenthesis depth 
        instead of using complex regular expressions.
        """
        if not os.path.exists(self.sql_file_path):
            raise FileNotFoundError(f"SQL file not found: {self.sql_file_path}")

        # Read UTF-16 SQL file safely (handling potential BOM variations)
        for enc in ('utf-16', 'utf-16-le', 'utf-16-be'):
            try:
                with open(self.sql_file_path, 'r', encoding=enc, errors='replace') as f:
                    self.sql_content = f.read()
                break
            except UnicodeError:
                continue

        extracted_scripts = {}
        upper_content = self.sql_content.upper()
        table_names = self.load_table_names()
        
        for table in table_names:
            # Construct the exact header target, e.g., [OP10_Continuity_testing_Air_And_vacuum_Cleaning]
            target_header = f"[{table}]".upper()
            
            # Find where CREATE TABLE and our target table occur
            # We look for "CREATE TABLE" followed somewhere by our bracketed table name
            pos = 0
            found_script = None
            
            while True:
                create_idx = upper_content.find("CREATE TABLE", pos)
                if create_idx == -1:
                    break
                    
                target_idx = upper_content.find(target_header, create_idx)
                # Ensure the table name immediately follows CREATE TABLE (allowing for schema like [dbo].)
                if target_idx != -1 and target_idx - create_idx < 50:
                    # Found the start of our table block! Now track parentheses to find the end.
                    paren_depth = 0
                    start_char_idx = create_idx
                    end_char_idx = -1
                    recording = False
                    
                    for i in range(create_idx, len(self.sql_content)):
                        char = self.sql_content[i]
                        if char == '(':
                            if not recording:
                                recording = True
                            paren_depth += 1
                        elif char == ')':
                            paren_depth -= 1
                        
                        if recording and paren_depth == 0:
                            end_char_idx = i + 1
                            # Look slightly ahead for the terminating semicolon
                            while end_char_idx < len(self.sql_content) and self.sql_content[end_char_idx].isspace():
                                end_char_idx += 1
                            if end_char_idx < len(self.sql_content) and self.sql_content[end_char_idx] == ';':
                                end_char_idx += 1
                            break
                    
                    if end_char_idx != -1:
                        found_script = self.sql_content[start_char_idx:end_char_idx].strip()
                        break
                
                pos = create_idx + 12 # Move past this "CREATE TABLE" and search again

            extracted_scripts[table] = found_script
            
        # return extracted_scripts
        print(extracted_scripts)
    # def parse(self):
    #     self.logger =  setup_logger(name='Sql Validator')
    #     self.sql_file_path = Path(get_sqlfile_path())
    #     self.master_columns = get_master_columns()


    #     with open (self.sql_file_path, 'r', encoding='utf-16') as sqlFile:
    #         file = sqlFile.read()
    #         pattern  =  re.compile(r"CREATE\s+TABLE\b", re.IGNORECASE)
    #         tables: list[str] = []
    #         sql = ""

    #         tableNames = set()
    #         for match in pattern.finditer(file):
    #             start = match.start()

    #             # find first opening parentheses
    #             pos = file.find("()", start)

    #             depth = 1
    #             i = pos + 1

    #             while i < len(file) and depth:
    #                 if file[i] == "(":
    #                     depth += 1
    #                 elif file[i] == ")":
    #                     depth += -1
    #                 i += 1

    #             # include trailing semi-colon
    #             if i < len(file) and file[i] == ";":
    #                 i+= 1

    #             tables.append(file[start:i])
    #             sql = file[start:i]
    #         # get table names
    #     with pd.ExcelWriter("schema.xlsx", engine="openpyxl") as writer:
    #         for table in tables:
    #             match = re.search(
    #                 r"CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?([`\"\[\]\w\.]+)",
    #                 table,
    #                 re.IGNORECASE,
    #             )
    #             # create excel file

    #             # if match:
    #             #     # print(table_name[6:])
    #                 # tableNames.add(table_name[6:])
    #             if not match:
    #                 continue

    #             table_name = match.group(1).replace('"', '').replace('`', '')
    #             table_name = table_name.replace("[", "").replace("]", "")
    #             table_name = table_name.replace("`", "").replace('"', "")
    #             sheet_name = table_name.split(".")[-1][:31]   # Excel sheet names max 31 chars

    #             cols_text = table[table.find("(")+1 : table.rfind(")")]

                

    #             rows = []

    #             for line in cols_text.splitlines():
    #                 line = line.strip().rstrip(",")

    #                 if not line:
    #                     continue

    #                 # Skip constraints
    #                 if re.match(
    #                     r"^(PRIMARY|FOREIGN|UNIQUE|CHECK|CONSTRAINT|KEY|INDEX)\b",
    #                     line,
    #                     re.IGNORECASE,
    #                 ):
    #                     continue

    #                 # Extract column name and datatype
    #                 m = re.match(r'["`\[]?(\w+)["`\]]?\s+([A-Za-z]+(?:\([^)]+\))?)', line)

    #                 if m:
    #                     rows.append({
    #                         "Column": m.group(1),
    #                         "Data Type": m.group(2)
    #                     })

    #             df = pd.DataFrame(rows)
    #             df.to_excel(writer, sheet_name=sheet_name, index=False)

                


    #         # print(tableNames)    


            


        


        


