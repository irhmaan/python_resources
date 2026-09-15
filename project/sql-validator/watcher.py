import sys

from watchfiles import run_process, PythonFilter

run_process(
    ".",
    target=f"{sys.executable} main.py",
    watch_filter=PythonFilter(),
)