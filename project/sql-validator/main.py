from reader.excel_reader import ExcelReader

def main():
    print("we are running")
    reader = ExcelReader("data/data_test.xlsx")

    tables = reader.read()

    for table in tables:
        print(table)



if __name__ == "__main__":
    main()