# FastAPI Echo API

A simple Echo API that returns request details including headers, body, and path for any endpoint.

## Features

- Supports any HTTP path
- Returns request headers
- Returns request body (for POST, PUT, PATCH methods)
- Returns request path
- Supports all HTTP methods (GET, POST, PUT, DELETE, PATCH, HEAD, OPTIONS)

## Installation

1. Install dependencies:
```bash
pip install -r requirements.txt
```

2. Run the server:
```bash
python main.py
```

The API will be available at `http://localhost:8000`

## Usage Examples

1. Make a POST request with JSON body:
```bash
curl -X POST http://localhost:8000/any/path \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello, World!"}'
```

2. Make a GET request:
```bash
curl http://localhost:8000/test/path
```

3. Test error responses:

   a. Client Errors (4xx):
   ```bash
   # 400 Bad Request
   curl http://localhost:8000/error/400
   
   # 401 Unauthorized
   curl http://localhost:8000/error/401
   
   # 403 Forbidden
   curl http://localhost:8000/error/403
   
   # 404 Not Found
   curl http://localhost:8000/error/404
   ```

   b. Server Errors (5xx):
   ```bash
   # 500 Internal Server Error
   curl http://localhost:8000/error/500
   
   # 503 Service Unavailable
   curl http://localhost:8000/error/503
   ```

   All error responses will include:
   - HTTP status code
   - Error detail message
   - X-Process-Time header
   - X-Correlation-ID header
   
   Example error response:
   ```json
   {
     "detail": "Bad request demonstration"
   }
   ```

   The error will also be logged with:
   - Correlation ID
   - Request path
   - Error details
   - Status code
   - Response time
   - HTTP method
   - Service name

4. Access the API documentation:
- OpenAPI UI: http://localhost:8000/docs
- ReDoc UI: http://localhost:8000/redoc

## Docker Deployment

1. Build the Docker image:
```bash
docker build -t fastapi-echo .
```

2. Run the container:
```bash
docker run -d -p 8000:8000 fastapi-echo
```

The API will be available at `http://localhost:8000`

You can also use the provided Docker image in your production environment by adjusting the port mapping and adding any necessary environment variables.

## Multi-Architecture Docker Build

This application supports multi-architecture Docker builds for both AMD64 (Intel/AMD) and ARM64 (Apple Silicon/ARM) processors.

### Prerequisites

- Docker Desktop with BuildKit support
- Docker Hub account (or another container registry)

### Building for Multiple Architectures

1. Create and use a new builder instance:
```bash
docker buildx create --name multiarch --driver docker-container --bootstrap --use
```

2. Build and push the multi-architecture image:
```bash
docker buildx build --platform linux/amd64,linux/arm64 -t <your-username>/fastapi-echo:latest --push .
```

Replace `<your-username>` with your Docker Hub username.

3. Verify the multi-architecture support:
```bash
docker buildx imagetools inspect <your-username>/fastapi-echo:latest
```

The image can now be used on both Intel/AMD and ARM-based systems without any modifications. Docker will automatically pull the correct version for your system's architecture.

### Running the Multi-Architecture Image

```bash
docker run -d -p 8000:8000 <your-username>/fastapi-echo:latest
```

## Datadog Monitoring

The application is configured with Datadog monitoring and structured logging. Each log entry includes:

- Request path
- Response time
- Status code
- Error messages (if any)
- Correlation ID
- HTTP method
- Service name (fastapi-echo)
- Environment
- Custom tags

### Running with Datadog Agent

1. Make sure you have the Datadog agent running on your host:
```bash
docker run -d --name dd-agent \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -v /proc/:/host/proc/:ro \
  -v /sys/fs/cgroup/:/host/sys/fs/cgroup:ro \
  -e DD_API_KEY=<YOUR_DATADOG_API_KEY> \
  -e DD_SITE="datadoghq.com" \
  gcr.io/datadoghq/agent:latest
```

2. Run the FastAPI Echo container with Datadog integration:
```bash
docker run -d \
  --name fastapi-echo \
  -p 8000:8000 \
  --link dd-agent:dd-agent \
  -e DD_AGENT_HOST=dd-agent \
  -e DD_API_KEY=<YOUR_DATADOG_API_KEY> \
  fastapi-echo
```

### Log Format

The application generates structured JSON logs with the following format:
```json
{
  "timestamp": "2025-02-01T14:26:14+07:00",
  "level": "INFO",
  "service": "fastapi-echo",
  "correlation_id": "550e8400-e29b-41d4-a716-446655440000",
  "request_path": "/api/test",
  "status_code": 200,
  "response_time": 0.0034,
  "method": "GET",
  "message": "Request processed successfully"
}
```

### Monitoring in Datadog

You can monitor the following metrics in your Datadog dashboard:

1. Request metrics:
   - Response times (average, p95, p99)
   - Request count by path
   - Error rate
   - Status code distribution

2. Custom metrics:
   - Service name: fastapi-echo
   - Environment: production
   - Version: 1.0.0

3. Distributed tracing:
   - Request traces
   - Error traces
   - Correlation between logs and traces
