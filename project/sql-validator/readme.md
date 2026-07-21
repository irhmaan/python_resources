# Project Structure

```text
sql-validator/
│
├── main.py                  # Application entry point
├── requirements.txt         # Project dependencies
├── README.md                # Project documentation
│
├── data/
│   └── data_test.xlsx            # Sample xlsx file
│
├── reader/
│   ├── __init__.py
│   └── excel_reader.py        # Reads and parses excel file
│
├── validator/
│   ├── __init__.py
│   └── table_validator.py   # Validates table schema and data
│
├── models/
│   ├── __init__.py
│   └── table.py             # Table data model
│
└── common/
    └── logger.py            # Logging utilities
    └── load_config.py       # load config.yml
    └── app_log.py           # load app keys
```
