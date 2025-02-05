#!/bin/bash

ALB_URL="abc1234-dd-demo-fe-alb-1771641178.us-east-1.elb.amazonaws.com"

# Function to send requests with random data
send_requests() {
    # GET requests
    http GET "http://$ALB_URL/"
    http GET "http://$ALB_URL/echo"
    http GET "http://$ALB_URL/api/v1/profile"
    http GET "http://$ALB_URL/my-orders"
    http GET "http://$ALB_URL/support"
    
    # POST requests with different payloads
    http POST "http://$ALB_URL/echo" message="Testing ALB logging"
    http POST "http://$ALB_URL/echo" data:='{"key1": "value1", "key2": "value2"}'
    http POST "http://$ALB_URL/api/v1/echo" data:='{"key1": "value1", "key2": "value2"}'
    http POST "http://$ALB_URL/api/v1/orders" data:='{"key1": "value1", "key2": "value2"}'
    http POST "http://$ALB_URL/api/v1/myaccount" data:='{"key1": "value1", "key2": "value2"}'
    
    # PUT requests
    http PUT "http://$ALB_URL/echo" message="Updating resource"
    
    # DELETE request
    http DELETE "http://$ALB_URL/echo"
    
    # HEAD request
    http HEAD "http://$ALB_URL/"
}

# Send requests in a loop
for i in {1..5}; do
    echo "Sending batch $i of requests..."
    send_requests
    sleep 2
done
