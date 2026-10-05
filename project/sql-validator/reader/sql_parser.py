import os
import pandas as pd
from common.logger import setup_logger
from common.app_config import get_sqlfile_path,get_encoding_schemes
from reader.excel_reader import ExcelReader
from pathlib import Path
import re

class SqlParser:
    # Read a sql file - we try with certain encoding schemes to avoid getting issue due to encoding scheme of file
    # Get table_names as this will be used to narrow down sql file parsing.
    # Extract create scripts and then use these to populate an excel sheet for each table name with columns and datatype.
    def __init__(self) -> None:
        self.logger =  setup_logger(name='validator')
        self.sql_file_path = Path(get_sqlfile_path())
        self.encodings_to_try = get_encoding_schemes()
        self.txt_path  = Path("Table_Names.txt")
        self.sql_content: str | None=None
        # self.oResult_fw = FileWriter('output/sql_parse_result.yml')
        self.table_name_list :  list[str]
        self.load_table_names()
        self.extract_create_scripts_by_parsing()
        

    def load_table_names(self ):

        """Reads table names from a text file."""
        if not os.path.exists(self.txt_path):
            raise FileNotFoundError(f"Table list file not found: {self.txt_path}")
        
        with open(self.txt_path, 'r', encoding='utf-8') as f:
            # strip() removes spaces, tabs, newlines, AND carriage returns (\r)
            return [line.strip() for line in f if line.strip() and not line.startswith('#')]


    def read_sql_file(self)->str | None:
        """
        Read Sql file from the specified path and return the file content.
        """
        if not os.path.exists(self.sql_file_path):
            self.logger.warning(f"Sql file not found: {self.sql_file_path}")
            raise FileNotFoundError(f"SQL file not found: {self.sql_file_path}")
        

        # Read UTF-16 SQL file safely
        if len(self.encodings_to_try) == 0:
            self.logger.warning("No encoding scheme found to read sql file")
            return

        self.logger.warning(f"reading file: {self.sql_file_path}")
        # Step 1: Read the first few bytes to check for a Binary BOM (Byte Order Mark)
        with open(self.sql_file_path, 'rb') as f:
            raw_bytes = f.read(4)
        # Detect encoding based on standard BOM signatures
        if raw_bytes.startswith(b'\xff\xfe') or raw_bytes.startswith(b'\xfe\xff'):
            detected_encoding = 'utf-16'
        elif raw_bytes.startswith(b'\xef\xbb\xbf'):
            detected_encoding = 'utf-8-sig'
        else:
            # If no explicit BOM, try standard encodings automatically in order of likelihood
            detected_encoding = None

        # Step 2: If BOM gave us a hint, try it first. Otherwise, loop through safe defaults.
        encodings_to_try = [detected_encoding] if detected_encoding else []
        encodings_to_try.extend(self.encodings_to_try)

        # Remove duplicates while preserving order
        encodings_to_try = list(dict.fromkeys([e for e in encodings_to_try if e]))

        for enc in encodings_to_try:
            try:
                with open(self.sql_file_path, 'r', encoding=enc, errors='replace') as f:
                    self.logger.info(f"[SUCCESS] Successfully read SQL file using encoding: {enc}")
                    self.sql_content = f.read()

                    return self.sql_content
                
                break
            except UnicodeError:
                continue

    def extract_create_scripts_by_parsing(self):

        """
        Safely extracts CREATE TABLE blocks by tracking parenthesis depth 
        instead of using complex regular expressions.
        """

        # sql_content : str | None=None 
        try:
            self.table_name_list = self.load_table_names()
            
            self.sql_content = self.read_sql_file()
            # 2. SANITIZE: Replace non-breaking spaces (\xa0) with regular spaces
            if not self.sql_content:
                self.logger.info(f"unable to read sql file content")
                return
            
            extracted_scripts = {}
            # print(self.table_name_list)

            if not self.table_name_list:
                self.logger.warning(f'Table_name file is empty{self.txt_path}')
                return

            for table in self.table_name_list:
                # Build a flexible regex pattern for the table header:
                # - Matches CREATE TABLE (case-insensitive, allows multiple spaces/newlines)
                # - Optional schema prefix like [dbo]. or dbo.
                # - The table name wrapped in optional brackets, allowing flexible spacing inside
                safe_table_name = re.escape(table)
                header_pattern = rf"(?i)CREATE\s+TABLE\s+(?:(?:\[[\w\s]+\]|\w+)\s*\.\s*)?\[?\s*{safe_table_name}\s*\]?\s*\("
                # header_pattern = rf"(?i)CREATE\s+TABLE\s+(?:(?:\[[\w\s]+\]|\w+)\s*\.\s*)?\[?\s*{safe_table_name}\s*\]?\s*\("

                # print(safe_table_name)
                # print(self.sql_content)
                match = re.search(header_pattern, self.sql_content) 
                # print(match)
                if not match:
                    extracted_scripts[table] = None
                    continue
                    
                # Once we find the start of the header, track parentheses to extract the full block
                start_idx = match.start()
                paren_depth = 0
                end_char_idx = -1
                recording = False
                
                for i in range(start_idx, len(self.sql_content)):
                    char = self.sql_content[i]
                    if char == '(':
                        if not recording:
                            recording = True
                        paren_depth += 1
                    elif char == ')':
                        paren_depth -= 1
                    
                    if recording and paren_depth == 0:
                        end_char_idx = i + 1
                        # Check for trailing semicolon
                        while end_char_idx < len(self.sql_content) and self.sql_content[end_char_idx].isspace():
                            end_char_idx += 1
                        if end_char_idx < len(self.sql_content) and self.sql_content[end_char_idx] == ';':
                            end_char_idx += 1
                        break
                        
                if end_char_idx != -1:
                    extracted_scripts[table] = self.sql_content[start_idx:end_char_idx].strip()
                else:
                    extracted_scripts[table] = None
                
            # return extracted_scripts
            # log to console - testing
            # print(extracted_scripts)
            # self.list_all_tables_in_sql(self.sql_content)
            self.parse_scripts_to_excel(extracted_scripts)

        except Exception as ex:
            self.logger.warning(f"Err occured: {ex}")

    
    def parse_scripts_to_excel(self, scripts_dict: dict, output_excel_path="output/table_schema.xlsx"):
        """
        Parses create scripts into column/datatype rows and saves them into an Excel workbook 
        where each table is a separate sheet.
        """

        # if no scripts found, return
        if all ( v is None for v in scripts_dict.values()):
            self.logger.warning("No create script found. Either source table names mismatch or sql file reading issue.")
            # self.diagnose_sql_search(self.sql_content, self.table_name_list)
            return

        # Create an Excel writer using openpyxl engine
        try:
            with pd.ExcelWriter(output_excel_path, engine='openpyxl') as writer:    
                        used_sheet_names = set()
                        # log to console - testing
                        # print(scripts_dict.values())
                        for table_name, script in scripts_dict.items():
                            if not script:
                                self.logger.info(f"[LOG] Skipping {table_name}: No script found.")
                                continue
                                
                            # 1. Extract content between outer parentheses of CREATE TABLE (...)
                            start_idx = script.find('(')
                            end_idx = script.rfind(')')
                            
                            if start_idx == -1 or end_idx == -1 or start_idx >= end_idx:
                                self.logger.info(f"[WARNING] Could not parse block boundaries for {table_name}")
                                continue
                                
                            inner_content = script[start_idx + 1:end_idx]
                            
                            # 2. Clean whitespace (newlines, tabs, double spaces)
                            cleaned_content = re.sub(r'[\r\n\t]+', ' ', inner_content)
                            cleaned_content = re.sub(r'\s+', ' ', cleaned_content).strip()
                            
                            # 3. Split by commas while respecting parentheses (e.g. DECIMAL(18, 2))
                            raw_defs = [d.strip() for d in cleaned_content.split(',')]
                            column_definitions = []
                            temp_def = ""
                            
                            for part in raw_defs:
                                if temp_def:
                                    temp_def += ", " + part
                                else:
                                    temp_def = part
                                if temp_def.count('(') == temp_def.count(')'):
                                    column_definitions.append(temp_def)
                                    temp_def = ""
                            if temp_def:
                                column_definitions.append(temp_def)
                            # print(column_definitions)
                            # 4. Extract Column Names and Datatypes, ignoring constraints
                            rows = []
                            for definition in column_definitions:
                                upper_def = definition.upper()
                                
                                # Ignore table-level constraints/keys/indexes
                                if any(upper_def.startswith(kw) for kw in ["CONSTRAINT", "PRIMARY KEY", "FOREIGN KEY", "CHECK", "UNIQUE", "INDEX"]):
                                    continue
                                # print(upper_def)
                                    
                                # Upgraded Regex: 
                                # Group 1/2: Column Name (with or without brackets)
                                # Group 3/4: Datatype Base (with or without brackets, e.g., VARCHAR)
                                # Group 5: Optional size/precision (e.g., (50) or (18, 2)), allowing optional spaces
                                match = re.match(
                                    r'^\s*(?:\[([\w\s]+)\]|([\w\s]+))\s+(?:\[([a-zA-Z0-9_]+)\]|([a-zA-Z0-9_]+))(?:\s*(\([^)]+\)))?', 
                                    definition
                                )
                                
                                if match:
                                    col_name = (match.group(1) or match.group(2)).strip()
                                    dtype_base = (match.group(3) or match.group(4)).strip()
                                    dtype_size = match.group(5) or "" # Captures (50) or (18, 2) if present
                                    
                                    # Combine datatype base and size (e.g., VARCHAR + (50) = VARCHAR(50))
                                    datatype = f"{dtype_base}{dtype_size}"
                                    
                                    rows.append({
                                        "COLUMN_NAME": col_name,
                                        "DATATYPE": datatype
                                    })
            
                            if not rows:
                                self.logger.info(f"[LOG] No columns parsed for {table_name}. Regex failed to parse columns/datatype for {table_name} ")
                                continue
            
                            # 5. Convert to Pandas DataFrame
                            df = pd.DataFrame(rows)
            
                            #5.5 convert table into pd df
                            tbl_df = pd.DataFrame(self.table_name_list)
                            
                            # 6. Format Sheet Name (Excel max limit is 31 characters)
                            sheet_name = table_name[:31]
                            
                            # Ensure unique sheet names in case truncation creates collisions
                            base_name = sheet_name
                            counter = 1
                            while sheet_name in used_sheet_names:
                                suffix = f"_{counter}"
                                sheet_name = base_name[:31 - len(suffix)] + suffix
                                counter += 1
                            used_sheet_names.add(sheet_name)
            
                            # write table names:
                            tbl_df.to_excel(writer, sheet_name='Table Name', index=False, header=['Name'], startcol=2,)
                            # 7. Write DataFrame to the specific sheet
                            df.to_excel(writer, sheet_name=sheet_name, index=False, header=False)
                            self.logger.info(f"[SUCCESS] Added sheet '{sheet_name}' with {len(rows)} columns.")
            
                        self.logger.info(f"\n[DONE] Excel successfully generated at: {output_excel_path}")

                        # call the excel reader and pass the output file to validate the schema  

            excel_reader = ExcelReader(file_path=output_excel_path)
            excel_reader.read() 

        except Exception as ex:
            self.logger.warning(f"Err occured: {ex}. Filepath: {output_excel_path}")

        
       


            


        


        


