from reader.excel_reader import ExcelReader
from common.logger import setup_logger
from common.app_config import enable_log,get_Excelfile_path
from common.load_config import load_config
from reader.sql_parser import SqlParser

def main():
    #* load config    
    load_config()
    # setup logger
    logger = setup_logger(enableLog=enable_log())
    logger.info("Application started")

    
    #* show menu when run.
    def showMenu():

        print("=== Welcome, please select a file type for checking ===\n")
        print(f"note: check you have place your file in data/target_file\n")

        print(f"For supported file structure, please check readme.txt")

        print(f"1. Excel File (xlsx)\n")
        print(f"2. Sql (.sql)\n")
        
        user_input = input(" ")
        option = user_input.strip()
        if option == "":
            print("Please provide a valid input !")
        
        menuOptions = {"1": "Excel File (xlsx)", "2": "Sql File (.sql)"}
        
        msg = menuOptions.get(option)
        
        print(f"\nProcessing your request for {msg}\n")
        match option:
            case "1": # parse excel 
                reader = ExcelReader(get_Excelfile_path())
                reader.read()
            case "2": # parse sql file
                # print("ain't gonna do itself, ")
                sqlParse = SqlParser()
                sqlParse.parse()

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
        input("\nPress Enter to close this window...")