import unittest
from lambda_function import process_alb_log
from datetime import datetime

class TestLambdaFunction(unittest.TestCase):
    def test_process_alb_log_with_http_prefix(self):
        # Test case for log entry with 'http' prefix
        log_entry = 'http 2025-02-03T10:27:12.917399Z app/dd-demo-fastapi-echo-alb/e1baeac3b9d0e87a 49.49.37.1:53271 172.31.53.221:8000 0.001 0.002 0.000 200 200 136 563 "GET http://dd-demo-fastapi-echo-alb-686843588.us-east-1.elb.amazonaws.com:80/echo/test1 HTTP/1.1" "curl/8.7.1" - - arn:aws:elasticloadbalancing:us-east-1:405381632321:targetgroup/dd-demo-fastapi-echo-tg/77b029cbea931ec0 "Root=1-67a09a00-0903cde3108ec6d905d34f85" "-" "-" 0 2025-02-03T10:27:12.914000Z "forward" "-" "-" "172.31.53.221:8000" "200" "-" "-" TID_bad8dd1682ead5408a67bc89d6ae1af8'
        
        result = process_alb_log(log_entry)
        
        self.assertIsNotNone(result)
        self.assertEqual(result['http']['method'], 'GET')
        self.assertEqual(result['http']['url'], '/echo/test1')
        self.assertEqual(result['http']['status_code'], 200)
        self.assertEqual(result['http']['target_status_code'], 200)
        self.assertEqual(result['network']['client']['ip'], '49.49.37.1')
        self.assertEqual(result['network']['bytes_read'], 136)
        self.assertEqual(result['network']['bytes_written'], 563)
        self.assertEqual(result['duration']['request_processing'], 0.001)
        self.assertEqual(result['duration']['target_processing'], 0.002)
        self.assertEqual(result['duration']['response_processing'], 0.000)

    def test_process_alb_log_without_http_prefix(self):
        # Test case for log entry without 'http' prefix
        log_entry = '2025-02-03T10:27:12.917399Z app/dd-demo-fastapi-echo-alb/e1baeac3b9d0e87a 49.49.37.1:53271 172.31.53.221:8000 0.001 0.002 0.000 200 200 136 563 "GET /echo/test1 HTTP/1.1" "curl/8.7.1" - - arn:aws:elasticloadbalancing:us-east-1:405381632321:targetgroup/dd-demo-fastapi-echo-tg/77b029cbea931ec0 "Root-1-67a09a00-0903cde3108ec6d905d34f85" "-" "-" 0 2025-02-03T10:27:12.914000Z "forward" "-" "-" "172.31.53.221:8000" "200" "-" "-" TID_bad8dd1682ead5408a67bc89d6ae1af8'
        
        result = process_alb_log(log_entry)
        
        self.assertIsNotNone(result)
        self.assertEqual(result['http']['method'], 'GET')
        self.assertEqual(result['http']['url'], '/echo/test1')
        self.assertEqual(result['http']['status_code'], 200)
        self.assertEqual(result['http']['target_status_code'], 200)

    def test_process_alb_log_invalid_timestamp(self):
        # Test case for invalid timestamp
        log_entry = 'invalid_timestamp app/dd-demo-fastapi-echo-alb/e1baeac3b9d0e87a 49.49.37.1:53271 172.31.53.221:8000 0.001 0.002 0.000 200 200 136 563 "GET /echo/test1 HTTP/1.1" "curl/8.7.1" - -'
        
        result = process_alb_log(log_entry)
        self.assertIsNone(result)

    def test_process_alb_log_invalid_fields(self):
        # Test case for invalid number of fields
        log_entry = '2025-02-03T10:27:12.917399Z app/alb 49.49.37.1:53271'
        
        result = process_alb_log(log_entry)
        self.assertIsNone(result)

    def test_process_alb_log_invalid_numbers(self):
        # Test case for invalid numeric fields
        log_entry = '2025-02-03T10:27:12.917399Z app/dd-demo-fastapi-echo-alb/e1baeac3b9d0e87a 49.49.37.1:53271 172.31.53.221:8000 invalid invalid invalid invalid invalid invalid invalid "GET /echo/test1 HTTP/1.1" "curl/8.7.1" - -'
        
        result = process_alb_log(log_entry)
        self.assertIsNone(result)

if __name__ == '__main__':
    unittest.main()
