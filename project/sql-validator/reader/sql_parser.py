from common.logger import setup_logger
from common.app_config import get_sqlfile_path,get_master_columns
from pathlib import Path
import re
import pandas as pd

class SqlParser:
    # load a sql file.
    # sanitize the file only need to extract create statements. encoding scheme should be utf-16.
    # create a temporary file with the sanitized file and then start checking it
    # 
    def parse(self):
        self.logger =  setup_logger(name='Sql Validator')
        self.sql_file_path = Path(get_sqlfile_path())
        self.master_columns = get_master_columns()


        with open (self.sql_file_path, 'r', encoding='utf-16') as sqlFile:
            file = sqlFile.read()
            pattern  =  re.compile(r"CREATE\s+TABLE\b", re.IGNORECASE)
            tables: list[str] = []
            sql = ""

            tableNames = set()
            for match in pattern.finditer(file):
                start = match.start()

                # find first opening parentheses
                pos = file.find("()", start)

                depth = 1
                i = pos + 1

                while i < len(file) and depth:
                    if file[i] == "(":
                        depth += 1
                    elif file[i] == ")":
                        depth += -1
                    i += 1

                # include trailing semi-colon
                if i < len(file) and file[i] == ";":
                    i+= 1

                tables.append(file[start:i])
                sql = file[start:i]
            # get table names
        with pd.ExcelWriter("schema.xlsx", engine="openpyxl") as writer:
            for table in tables:
                match = re.search(
                    r"CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?([`\"\[\]\w\.]+)",
                    table,
                    re.IGNORECASE,
                )
                # create excel file

                # if match:
                #     # print(table_name[6:])
                    # tableNames.add(table_name[6:])
                if not match:
                    continue

                table_name = match.group(1).replace('"', '').replace('`', '')
                table_name = table_name.replace("[", "").replace("]", "")
                table_name = table_name.replace("`", "").replace('"', "")
                sheet_name = table_name.split(".")[-1][:31]   # Excel sheet names max 31 chars

                cols_text = table[table.find("(")+1 : table.rfind(")")]

                

                rows = []

                for line in cols_text.splitlines():
                    line = line.strip().rstrip(",")

                    if not line:
                        continue

                    # Skip constraints
                    if re.match(
                        r"^(PRIMARY|FOREIGN|UNIQUE|CHECK|CONSTRAINT|KEY|INDEX)\b",
                        line,
                        re.IGNORECASE,
                    ):
                        continue

                    # Extract column name and datatype
                    m = re.match(r'["`\[]?(\w+)["`\]]?\s+([A-Za-z]+(?:\([^)]+\))?)', line)

                    if m:
                        rows.append({
                            "Column": m.group(1),
                            "Data Type": m.group(2)
                        })

                df = pd.DataFrame(rows)
                df.to_excel(writer, sheet_name=sheet_name, index=False)

                


            # print(tableNames)    


            


        


        


