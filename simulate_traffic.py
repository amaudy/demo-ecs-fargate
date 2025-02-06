import requests
import random
import time
from datetime import datetime
import concurrent.futures

# Configuration
ALB_URL = "http://abc1234-dd-demo-fe-alb-982008623.us-east-1.elb.amazonaws.com"
NUM_REQUESTS = 1000  # Total number of requests to make
CONCURRENT_USERS = 5  # Number of concurrent users/threads

# Sample data
products = [
    "iphone-14-pro", "macbook-air-m2", "airpods-pro",
    "ipad-pro", "apple-watch-8", "mac-studio"
]

user_ids = [f"user_{i}" for i in range(1, 11)]
categories = ["electronics", "computers", "accessories"]

def generate_random_request():
    """Generate a random API request"""
    endpoints = [
        # Products
        ("GET", f"/api/products/{random.choice(products)}", None),
        ("GET", f"/api/products?category={random.choice(categories)}", None),
        ("POST", "/api/products/search", {"query": random.choice(["apple", "pro", "mac", "air"])}),
        
        # Cart
        ("GET", f"/api/cart/{random.choice(user_ids)}", None),
        ("POST", f"/api/cart/{random.choice(user_ids)}/add", {
            "product_id": random.choice(products),
            "quantity": random.randint(1, 3)
        }),
        
        # Orders
        ("GET", f"/api/orders/{random.choice(user_ids)}", None),
        ("POST", f"/api/orders/{random.choice(user_ids)}/create", {
            "products": [{"id": random.choice(products), "quantity": random.randint(1, 2)}
                        for _ in range(random.randint(1, 3))]
        }),
        
        # Reviews
        ("GET", f"/api/products/{random.choice(products)}/reviews", None),
        ("POST", f"/api/products/{random.choice(products)}/reviews", {
            "rating": random.randint(1, 5),
            "comment": "Great product!"
        })
    ]
    
    return random.choice(endpoints)

def send_request():
    """Send a single request to the ALB"""
    method, path, data = generate_random_request()
    url = f"{ALB_URL}{path}"
    
    try:
        if method == "GET":
            response = requests.get(url, timeout=5)
        else:
            response = requests.post(url, json=data, timeout=5)
        
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
