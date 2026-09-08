"""
NIRIKSHAK AI - Centralized Logging Configuration.

Provides structured logging across the backend and worker services.
"""

import logging
import sys
from typing import Optional

from app.core.config import get_settings


def setup_logging(service_name: Optional[str] = None) -> logging.Logger:
    """
    Configure and return the application logger.

    Args:
        service_name: Name of the service (e.g., 'backend', 'worker').
                      Defaults to 'nirikshak'.

    Returns:
        Configured logger instance.
    """
    settings = get_settings()
    name = service_name or "nirikshak"
    logger = logging.getLogger(name)

    # Avoid adding handlers multiple times
    if logger.handlers:
        return logger

    level = logging.DEBUG if settings.debug else logging.INFO
    logger.setLevel(level)

    # Console handler with structured format
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(level)

    formatter = logging.Formatter(
        fmt="%(asctime)s | %(levelname)-8s | %(name)s | %(module)s:%(funcName)s:%(lineno)d | %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )
    console_handler.setFormatter(formatter)
    logger.addHandler(console_handler)

    # File handler for persistent logs
    try:
        file_handler = logging.FileHandler(f"logs/{name}.log", mode="a")
        file_handler.setLevel(logging.INFO)
        file_handler.setFormatter(formatter)
        logger.addHandler(file_handler)
    except (OSError, FileNotFoundError):
        # logs directory may not exist in all environments
        logger.warning("Could not create file log handler. Logging to console only.")

    return logger


def get_logger(module_name: str) -> logging.Logger:
    """
    Get a child logger for a specific module.

    Args:
        module_name: Name of the module requesting the logger.

    Returns:
        Child logger instance.
    """
    parent = logging.getLogger("nirikshak")
    if not parent.handlers:
        setup_logging("nirikshak")
    return parent.getChild(module_name)
