import boto3
import gzip
import json
import os
import urllib.request
import base64
import re
from datetime import datetime

def get_dd_api_key():
    """Retrieve Datadog API key from Secrets Manager."""
    secret_arn = os.environ['DD_API_KEY_SECRET_ARN']
    session = boto3.session.Session()
    client = session.client('secretsmanager')
    try:
        get_secret_value_response = client.get_secret_value(SecretId=secret_arn)
        return get_secret_value_response['SecretString']
    except Exception as e:
        print(f"Error retrieving secret: {str(e)}")
        raise

def forward_to_datadog(logs, dd_api_key):
    """Forward logs to Datadog."""
    dd_url = f"https://http-intake.logs.{os.environ.get('DD_SITE', 'us5.datadoghq.com')}/api/v2/logs"
    headers = {
        'Content-Type': 'application/json',
        'DD-API-KEY': dd_api_key
    }

    try:
        print(f"Sending logs to Datadog URL: {dd_url}")
        print(f"Request headers: {headers}")
        print(f"Request payload: {json.dumps(logs, indent=2)}")
        
        req = urllib.request.Request(
            dd_url,
            data=json.dumps(logs).encode('utf-8'),
            headers=headers,
            method='POST'
        )
        with urllib.request.urlopen(req) as response:
            print(f"Logs forwarded successfully. Status: {response.status}")
            print(f"Response headers: {dict(response.getheaders())}")
            response_body = response.read().decode('utf-8')
            print(f"Response body: {response_body}")
    except Exception as e:
        print(f"Error forwarding logs to Datadog: {str(e)}")
        raise

def process_alb_log(log_entry):
    """Process an ALB log entry and extract relevant fields."""
    try:
        # Remove 'http ' prefix if present
        if log_entry.startswith('http '):
            log_entry = log_entry[5:]

        # Split the log entry into space-separated fields, preserving quoted strings
        fields = []
        current_field = []
        in_quotes = False
        
        for char in log_entry:
            if char == '"':
                in_quotes = not in_quotes
                current_field.append(char)
            elif char == ' ' and not in_quotes:
                if current_field:
                    fields.append(''.join(current_field))
                    current_field = []
            else:
                current_field.append(char)
        
        if current_field:
            fields.append(''.join(current_field))

        # We expect at least 12 fields in a valid ALB log entry
        if len(fields) < 12:
            print(f"Invalid number of fields in log entry: {len(fields)}")
            return None

        # Parse timestamp (field 0)
        try:
            timestamp = datetime.strptime(fields[0], '%Y-%m-%dT%H:%M:%S.%fZ')
            print(f"Successfully parsed timestamp: {fields[0]}")
        except ValueError as e:
            print(f"Error parsing timestamp: {e}")
            return None

        # Parse request (field 11)
        request = fields[11].strip('"').split(' ')
        if len(request) < 2:
            print(f"Invalid request format: {fields[11]}")
            return None

        method = request[0]
        path = request[1]
        if path.startswith('http://') or path.startswith('https://'):
            # Extract path from full URL
            url_parts = path.split('/', 3)
            path = '/' + (url_parts[3] if len(url_parts) > 3 else '')

        # Parse numeric fields with error handling
        def safe_float(value):
            try:
                return float(value) if value not in ('-', 'invalid') else 0.0
            except ValueError:
                return 0.0

        def safe_int(value):
            try:
                return int(value)
            except ValueError:
                return 0

        # Create the log record
        log_record = {
            'timestamp': timestamp.isoformat(),
            'ddsource': 'alb',
            'host': fields[1],  # ALB name
            'service': "ecom-api",
            'http': {
                'method': method,
                'url': path,
                'status_code': safe_int(fields[7]),  # ELB status code
                'target_status_code': safe_int(fields[8])  # Target status code
            },
            'network': {
                'client': {
                    'ip': fields[2].split(':')[0]  # Client IP
                },
                'bytes_read': safe_int(fields[9]),  # Received bytes
                'bytes_written': safe_int(fields[10])  # Sent bytes
            },
            'duration': {
                'request_processing': safe_float(fields[4]),  # Request processing time
                'target_processing': safe_float(fields[5]),  # Target processing time
                'response_processing': safe_float(fields[6])  # Response processing time
            }
        }

        print(f"Successfully processed log entry: {log_record}")
        return log_record

    except Exception as e:
        print(f"Error processing log entry: {e}")
        print(f"Log entry: {log_entry}")
        return None

def process_logs(logs, context):
    try:
        # Get tags from environment variables
        dd_tags = os.environ.get('DD_TAGS', '')
        
        # Process each log entry
        for log in logs:
            # Add default tags
            log['tags'] = [
                dd_tags,
                f"forwardername:{context.function_name}",
                f"forwarder_memorysize:{context.memory_limit_in_mb}",
                f"forwarder_version:{os.environ.get('FORWARDER_VERSION', 'unknown')}",
                f"source:aws.alb",
                f"service:alb"
            ]
            
            # Add ALB name tag
            if 'alb' in log and 'name' in log['alb']:
                log['tags'].append(f"loadbalancer:{log['alb']['name']}")
            
            # Join all tags
            log['ddtags'] = ','.join(tag for tag in log['tags'] if tag)
        
        return logs
    
    except Exception as e:
        print(f"Error processing logs: {str(e)}")
        raise

def lambda_handler(event, context):
    """Main Lambda handler."""
    try:
        print(f"Processing event: {json.dumps(event)}")
        dd_api_key = get_dd_api_key()
        print("Successfully retrieved Datadog API key")
        
        # Process S3 events
        for record in event.get('Records', []):
            if record.get('eventSource') != 'aws:s3':
                print(f"Skipping non-S3 event: {record.get('eventSource')}")
                continue

            s3 = boto3.client('s3')
            bucket = record['s3']['bucket']['name']
            key = record['s3']['object']['key']
            print(f"Processing S3 object: s3://{bucket}/{key}")

            # Get the log file from S3
            response = s3.get_object(Bucket=bucket, Key=key)
            content = response['Body'].read()
            print(f"Successfully read {len(content)} bytes from S3")

            # Decompress if gzipped
            if key.endswith('.gz'):
                content = gzip.decompress(content)
                print(f"Decompressed content to {len(content)} bytes")

            # Process each log line
            logs = []
            content_str = content.decode('utf-8')
            total_lines = content_str.count('\n')
            print(f"Processing {total_lines} log lines")
            
            for line in content_str.splitlines():
                if line.strip():
                    log_entry = process_alb_log(line)
                    if log_entry:
                        logs.append(log_entry)

            print(f"Successfully processed {len(logs)} log entries")

            # Process logs and add tags
            logs = process_logs(logs, context)

            # Forward logs in batches of 1000
            batch_size = 1000
            for i in range(0, len(logs), batch_size):
                batch = logs[i:i + batch_size]
                print(f"Forwarding batch of {len(batch)} logs to Datadog")
                forward_to_datadog(batch, dd_api_key)

        return {
            'statusCode': 200,
            'body': json.dumps('Log forwarding completed successfully')
        }

    except Exception as e:
        print(f"Error processing logs: {str(e)}")
        raise
