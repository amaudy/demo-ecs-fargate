import requests
import random
import time
from datetime import datetime
import concurrent.futures

# Configuration
ALB_URL = "http://abc1234-dd-demo-fe-alb-982008623.us-east-1.elb.amazonaws.com"
NUM_REQUESTS = 10  # Total number of requests to make
CONCURRENT_USERS = 5  # Number of concurrent users/threads

# Sample data
error_endpoints = [
    "/error/400",
    "/error/401",
    "/error/403",
    "/error/404",
    "/error/500",
    "/error/503"
]

echo_paths = [
    "/api/v1/products",
    "/api/v1/users",
    "/api/v1/orders",
    "/api/v1/cart",
    "/api/v1/reviews",
    "/health",
    "/metrics",
    "/status"
]

http_methods = ["GET", "POST", "PUT", "DELETE", "PATCH"]

# Add common browser user agents
user_agents = [
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2.1 Safari/605.1.15",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Edge/120.0.0.0",
    "Mozilla/5.0 (iPhone; CPU iPhone OS 17_2_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Mobile/15E148 Safari/604.1",
    "Mozilla/5.0 (iPad; CPU OS 17_2_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Mobile/15E148 Safari/604.1"
]

def generate_random_request():
    """Generate a random API request"""
    # 30% chance to hit error endpoints, 70% chance for echo endpoints
    if random.random() < 0.3:
        return ("GET", random.choice(error_endpoints), None)
    else:
        return (
            random.choice(http_methods),
            random.choice(echo_paths),
            {"message": "Test payload"} if random.random() < 0.5 else None
        )

def send_request():
    """Send a single request to the ALB"""
    method, path, data = generate_random_request()
    url = f"{ALB_URL}{path}"
    
    # Add random user agent to headers
    headers = {
        "User-Agent": random.choice(user_agents)
    }
    
    try:
        if method == "GET":
            response = requests.get(url, headers=headers, timeout=5)
        else:
            response = requests.request(method, url, json=data, headers=headers, timeout=5)
        
        print(f"{datetime.now().isoformat()} - {method} {path} - Status: {response.status_code}")
    except Exception as e:
        print(f"{datetime.now().isoformat()} - {method} {path} - Error: {str(e)}")

def simulate_traffic():
    """Simulate traffic using multiple threads"""
    with concurrent.futures.ThreadPoolExecutor(max_workers=CONCURRENT_USERS) as executor:
        futures = []
        for _ in range(NUM_REQUESTS):
            futures.append(executor.submit(send_request))
            time.sleep(random.uniform(0.1, 0.5))  # Random delay between requests
        
        concurrent.futures.wait(futures)

if __name__ == "__main__":
    print(f"Starting traffic simulation to {ALB_URL}")
    print(f"Sending {NUM_REQUESTS} requests with {CONCURRENT_USERS} concurrent users")
    simulate_traffic()
