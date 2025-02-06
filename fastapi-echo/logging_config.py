import logging
import json
from pythonjsonlogger import jsonlogger
from typing import Any

class CustomJsonFormatter(jsonlogger.JsonFormatter):
    def add_fields(self, log_record: dict[str, Any], record: logging.LogRecord, message_dict: dict[str, Any]) -> None:
        super().add_fields(log_record, record, message_dict)
        
        # Add service name
        log_record['service'] = 'fastapi-echo'
        
        # Add log level
        log_record['level'] = record.levelname
        
        # Add timestamp
        log_record['timestamp'] = self.formatTime(record)
        
        # Add correlation ID if exists
        if hasattr(record, 'correlation_id'):
            log_record['correlation_id'] = record.correlation_id
            
        # Add request details if they exist
        if hasattr(record, 'request_path'):
            log_record['request_path'] = record.request_path
        if hasattr(record, 'status_code'):
            log_record['status_code'] = record.status_code
        if hasattr(record, 'response_time'):
            log_record['response_time'] = record.response_time
        if hasattr(record, 'error'):
            log_record['error'] = record.error

def setup_logging():
    logger = logging.getLogger("fastapi-echo")
    logger.setLevel(logging.INFO)
    
    # Create console handler
    handler = logging.StreamHandler()
    
    # Create formatter
    formatter = CustomJsonFormatter(
        '%(timestamp)s %(level)s %(name)s %(message)s'
    )
    
    # Add formatter to handler
    handler.setFormatter(formatter)
    
    # Add handler to logger
    logger.addHandler(handler)
    
    return logger
