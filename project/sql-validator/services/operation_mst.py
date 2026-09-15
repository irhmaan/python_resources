
from pathlib import Path
from common import( logger, file_writer)


class GenerateOperationMst:

    def __init__(self) -> None:
        self.logger = logger.setup_logger()
        self.fw = file_writer.FileWriter('OperationMst.sql')
        self.file_path = Path('Table_Names.txt')
        

        if not self.file_path.exists():
            raise FileNotFoundError(f'Could not locate the file path: {self.file_path}')
        else:
            self.logger.info('Generate Operation Mst: Table/Operation file Names: %s',self.file_path)

    def createOperationInsert(self):
        '''
        Generate an insert script for operation mst.
        '''
        self.fw.clear_content()

        with open(self.file_path, 'r', encoding='utf-8') as file:
            lines = file.readlines()

            sorted(lines, reverse=True)
            for line in lines:
                print(line)
                line = line.replace("[", "").replace("]","")
                line = line.replace("&", "and").replace("'", "")
            # prepare insert script here 

                stmt =  f'''
INSERT INTO OperationMst (ProfitCenterCode,CostCenterCode,OperationCode,OperationName,OperationType,isActive,ent_stamp,last_upd_stamp,ent_by,last_upd_by)
VALUES('desired_pcc', 'desired_ccc', 'OperationCode', '{line.rstrip()}', 'CALIPER', '1', GETDATE(),GETDATE(), 'JOB', 'JOB');
                        '''
                print(stmt)
                self.fw.write_file(stmt)

                

