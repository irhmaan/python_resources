from pathlib import Path
from common import( logger, file_writer)

class GenerateMachineMst:

    def __init__(self) -> None:
        self.logger = logger.setup_logger()
        self.fw = file_writer.FileWriter('output/MachineMst.sql')
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
INSERT INTO MachineMst(ProfitCenterCode,CostCenterCode,MachineCode,MachineName,MachineType,NoOfStations,IndexPerStations,PLCAddress,PLCMake,PLCModel,ChannelName,DeviceName,isActive,ImagePath,ent_stamp,last_upd_stamp,ent_by,last_upd_by,PCInterfaceIPAddress)
VALUES('desired_ppc', 'desired_ccc', 'MachineCode', '{line.rstrip()}', 'CALIPER', '1', '1' , NULL, NULL, NUll, NULL, NULL, '1', NULL, GETDATE(),GETDATE(), 'script', 'script', 
NULL);
                        '''
                print(stmt)
                self.fw.write_file(stmt)