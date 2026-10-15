
from pathlib import Path
from common import( logger, file_writer)
from common.app_config import AppConfig


class GenerateRoutingConfigDetailsMst:

    def __init__(self) -> None:
        self.logger = logger.setup_logger()
        self.fw = file_writer.FileWriter('output/RoutingConfigDetails.sql')
        self.line_data = AppConfig.LINE_DATA 
        self.rcd_template_file_path = AppConfig.ROUTING_CONFIG_TEMPLATE       

        if not self.line_data:
            self.logger.warning(f'No line specific data available: {self.line_data}')
            return
        elif not self.rcd_template_file_path:
            self.logger.warning(f'No rcd template file found: {self.rcd_template_file_path}')
            return
        else:
            self.logger.info("Generate RoutingConfigDetails data file :%s with template %s" , self.fw.file_path, self.rcd_template_file_path)
            # self.line_data

        self.create()


    def create(self):
        '''
        Generate an insert script for RoutingConfigDetails.
        '''
        self.fw.clear_content()

        with open(self.rcd_template_file_path, 'r', encoding='utf-8') as file:
            lines = file.readlines()
            profit_center_code= self.line_data['profitCenterCode']
            line_code = self.line_data['line_code']
            self.logger.info(f"Line and profitcentercode:  {line_code}, {profit_center_code}")
            
            self.fw.clear_content()
            print("Generating...")
            sorted(lines, reverse=True)
            for line in lines:
                cleaned_line = line.strip()
                if cleaned_line.__contains__("@Target_ProfitCenter@"):
                    cleaned_line = cleaned_line.replace('@Target_ProfitCenter@', profit_center_code)
                if cleaned_line.__contains__("@Target_LineCode@"):
                    cleaned_line = cleaned_line.replace('@Target_LineCode@', line_code)

                if not cleaned_line:
                    continue
                
                self.fw.write_file(cleaned_line)

            # prepare insert script here 
            self.logger.info(f"Completed, check file at: {self.fw.file_path}")
                # print(stmt)

                

