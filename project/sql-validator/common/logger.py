import logging
from pathlib import Path
from datetime import datetime,timezone

def setup_logger(
    name: str = "my_app",
    level: int = logging.INFO,
) -> logging.Logger:
    """
    Create and configure a logger.

    Args:
        name: Logger name.
        log_file: Path to the log file.
        level: Logging level (DEBUG, INFO, WARNING, ERROR, CRITICAL).

    Returns:
        Configured logger instance.
    """
    utc_now = datetime.now(timezone.utc)
    date = utc_now.strftime("%Y-%m-%d")

    log_file = f"logs/{date}/app.log"
        
    # Create log directory if it doesn't exist
    Path(log_file).parent.mkdir(parents=True, exist_ok=True)

    logger = logging.getLogger(name)

    # Avoid adding handlers multiple times
    if logger.handlers:
        return logger

    logger.setLevel(level)

    formatter = logging.Formatter(
        "%(asctime)s | %(levelname)-8s | %(name)s | %(filename)s:%(lineno)d | %(message)s"
    )

    # Console handler
    console_handler = logging.StreamHandler()
    console_handler.setFormatter(formatter)

    # File handler
    file_handler = logging.FileHandler(log_file)
    file_handler.setFormatter(formatter)

    logger.addHandler(console_handler)
    logger.addHandler(file_handler)

    return logger