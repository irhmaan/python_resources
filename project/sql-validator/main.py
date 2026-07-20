from reader.excel_reader import ExcelReader

def main():
    # print("we are running")


    # for table in tables:
    #     print(table)
    # Add this at the exact end of your script
    print("=== Welcome, please select a file type for checking ===\n")
    print(f"note: check you have place your file in data/target_file\n")

    print(f"1. Excel File (xlsx)\n")
    print(f"2. Sql (.sql)\n")

        # 1. Take user input
    user_input = input(" ")

    if user_input != "":
        print(f"\nProcessing your request.\n")
        match user_input.strip():
            case "1":
                reader = ExcelReader("data/data_test.xlsx")
                reader.read()
            case "2":
                print("ain't gonna do itself, ")
            
    
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