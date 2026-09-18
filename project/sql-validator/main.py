from reader.excel_reader import ExcelReader
from common.logger import setup_logger
from common.load_config import init

from common import (
    app_config,
    load_config
)

from services import (operation_mst, machine_mst, mes_mode)

from reader.sql_parser import SqlParser


def main():
    #* load config    
    load_config.init()
    # setup logger
    logger = setup_logger(enableLog=app_config.enable_log())
    logger.info("Application started")

    
    #* show menu when run.
    def showMenu():

        print("=== Welcome, please select a option ===\n")
        print(f"note: check you have placed your file in data/target_file\n")

        print(f"For supported file structure, please check readme.txt")

        print("\nPress Enter or type 'exit' to exit the script...\n")

        while(True):


            menuOptions = {
                        "1": "Excel File (xlsx)", 
                        "2": "Sql File (.sql)", 
                        '3': 'Generate Operation Master',
                        '4': 'Generate Machine Master',
                        '5': 'Generate MES mode'                        
                        }
            for i , value in enumerate(menuOptions.values()):         
                print(f"{i+1}. {value}\n")


              
            user_input = input(" ")
            option = user_input.strip()
            # if option == "":
            #     print("Please provide a valid input !")

            

            if option.lower() in [ 'exit', '']:
                break

            msg = menuOptions.get(option)
            
            print(f"\nProcessing your request for {msg}\n")
            match option:
                case "1": # parse excel 
                    reader = ExcelReader(app_config.get_Excelfile_path())
                    reader.read()
                case "2": # parse sql file
                    # print("ain't gonna do itself, ")
                    sqlParse = SqlParser()
                    sqlParse.parse()
                case '3':
                    o =    operation_mst.GenerateOperationMst()
                    o.createOperationInsert()
                case '4':
                    mst = machine_mst.GenerateMachineMst()
                    mst.createOperationInsert()
                case '5':
                    mes = mes_mode.GenerateMESModes()
                    mes.__init__


        

    # 1. Take user input
    showMenu()

            
    
    # print(f"\nProcessing your request, {user_name}...")
    
    # input("\nPress Enter to exit...")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"\nAn error occurred: {e}")
    finally:
        # Keeps the executable window open at the very end
        # input("\nPress Enter to close this window...")
        pass