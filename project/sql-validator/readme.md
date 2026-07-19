# Project Structure

sql-validator/
│
├── main.py # entry point
├── requirements.txt
├── README.md
│
├── data/
│ └── books.csv
│
├── parser/
│ ├── **init**.py
│ └── csv_reader.py
│
├── validator/
│ ├── **init**.py
│ └── table_validator.py
│
├── models/
│ ├── **init**.py
│ └── table.py
│
└── utils/
└── logger.py
