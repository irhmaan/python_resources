from pathlib import Path

from common import (logger, file_writer, load_config)

class GenerateMESModes:
    '''
    Create MES mode script using template_1 & template_2 defined in /templates dir.
    '''
    def __init__(self):
        self.logger = logger.setup_logger()
        self.app_config = load_config.app_config
        self.template_1_path = self.app_config['template_1_path']
        self.template_2_path = self.app_config['template_2_path']

        self.ofileWrite = file_writer.FileWriter('output/Auto_MesModes.sql')
        self.table_names_file_path = Path('Table_Names.txt')
        
        self.mes_push_section = Path(fr'{self.template_1_path}')
        self.pick_count_section = Path(fr'{self.template_2_path}')

        self.logger.info(f'Template for mes_push_section: {self.mes_push_section}')

        if not self.table_names_file_path.exists():
            raise FileNotFoundError(f'Could not locate the file path: {self.table_names_file_path}')
        else:
            self.logger.info(f'Generate Mes mode referencing {self.table_names_file_path}for table names')

        #! get all table names and get the template and for each table name replace and append in output file
        #? step -1 
        self.ofileWrite.clear_content()
        with open(self.table_names_file_path, 'r', encoding='utf-8' ) as table_name_file:
            self.ofileWrite.write_file('/* ===================template_1_section====================== */')
            print('Generating mes modes as per template_1 ')
            for table_name in table_name_file:
                # print(table_name)
                table_name = 'PUSH_' + table_name.replace('&', 'and')
                #? step -2
                #! read from a (say) template 1 and replace the table name in that placeholder template
                with open(self.mes_push_section, 'r+', encoding='utf-8') as template_file:
                    for lines in template_file:
                        t_line =  lines.replace('@PlaceHolder@', table_name.rstrip())
                        self.ofileWrite.write_file(t_line.rstrip())

        with open(self.table_names_file_path, 'r', encoding='utf-8' ) as table_name_file:                
                self.ofileWrite.write_file('/* ===================template_2_section====================== */')
                stmt = r"else if(@P_Mode='GET_PUSHED_DATA_COUNT')" 
                self.ofileWrite.write_file(stmt)
                self.ofileWrite.write_file("begin")
                print('Generating GET_PUSHED_DATA_COUNT mode as per template_2 ')

                for table_name in table_name_file:
                    table_name = 'PUSH_' + table_name.replace('&', 'and')
                    # print(table_name)
                    
                    with open(self.pick_count_section, 'r', encoding='utf-8') as pCountSecitonFile:
                        for line in pCountSecitonFile:
                            n_line = line.replace('@PlaceHolder@', table_name.rstrip())
                            self.ofileWrite.write_file(n_line.rstrip())

                self.ofileWrite.write_file("end")
                

                    

