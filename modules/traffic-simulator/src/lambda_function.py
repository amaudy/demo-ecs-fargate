import json
import random
import urllib.request
import urllib.error
import urllib.parse
import time
import os
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor

# Common browser user agents for simulation
USER_AGENTS = [
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2.1 Safari/605.1.15',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.0.0',
    'Mozilla/5.0 (iPhone; CPU iPhone OS 17_2_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Mobile/15E148 Safari/604.1',
    'Mozilla/5.0 (iPad; CPU OS 17_2_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Mobile/15E148 Safari/604.1'
]

# API endpoints and methods
ERROR_ENDPOINTS = [
    ('GET', '/error/400'),
    ('GET', '/error/401'),
    ('GET', '/error/403'),
    ('GET', '/error/404'),
    ('GET', '/error/500'),
    ('GET', '/error/503')
]

ECHO_PATHS = [
    '/api/v1/products',
    '/api/v1/users',
    '/api/v1/orders',
    '/api/v1/cart',
    '/api/v1/reviews',
    '/health',
    '/metrics',
    '/status'
]

HTTP_METHODS = ['GET', 'POST', 'PUT', 'DELETE', 'PATCH']

def send_request(base_url):
    """Send a single request to a random endpoint."""
    # 30% chance to hit error endpoints, 70% chance for echo endpoints
    if random.random() < 0.3:
        method, endpoint = random.choice(ERROR_ENDPOINTS)
    else:
        method = random.choice(HTTP_METHODS)
        endpoint = random.choice(ECHO_PATHS)

    headers = {
        'User-Agent': random.choice(USER_AGENTS),
        'Content-Type': 'application/json'
    }
    
    url = f"{base_url.rstrip('/')}{endpoint}"
    try:
        if method == 'GET':
            request = urllib.request.Request(url, headers=headers, method='GET')
        else:
            # For non-GET requests, add a test payload
            data = json.dumps({'message': 'Test payload'}).encode('utf-8')
            request = urllib.request.Request(url, data=data, headers=headers, method=method)

        with urllib.request.urlopen(request, timeout=10) as response:
            status_code = response.getcode()
            timestamp = datetime.now().isoformat()
            print(f"{timestamp} - {method} {endpoint} - Status: {status_code}")
            return True
            
    except urllib.error.HTTPError as e:
        print(f"HTTP Error sending request to {url}: {e.code} - {e.reason}")
        return False
    except urllib.error.URLError as e:
        print(f"URL Error sending request to {url}: {str(e)}")
        return False
    except Exception as e:
        print(f"Error sending request to {url}: {str(e)}")
        return False

def lambda_handler(event, context):
    """Lambda handler for traffic simulation."""
    base_url = os.environ.get('TARGET_URL')
    if not base_url:
        return {
            'statusCode': 400,
            'body': json.dumps('TARGET_URL environment variable is required')
        }
    
    num_requests = int(os.environ.get('NUM_REQUESTS', '10'))
    concurrent_users = int(os.environ.get('CONCURRENT_USERS', '5'))
    
    print(f"Starting traffic simulation to {base_url}")
    print(f"Sending {num_requests} requests with {concurrent_users} concurrent users")
    
    successful_requests = 0
    with ThreadPoolExecutor(max_workers=concurrent_users) as executor:
        futures = [executor.submit(send_request, base_url) for _ in range(num_requests)]
        for future in futures:
            if future.result():
                successful_requests += 1
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': 'Traffic simulation completed',
            'total_requests': num_requests,
            'successful_requests': successful_requests,
            'failed_requests': num_requests - successful_requests
        })
    }
