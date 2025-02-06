from fastapi import FastAPI, Request, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from typing import Any
import time
import uuid
from logging_config import setup_logging

# Initialize logging
logger = setup_logging()

app = FastAPI(title="Echo API")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    # Generate correlation ID
    correlation_id = str(uuid.uuid4())
    
    # Start timer
    start_time = time.time()
    
    try:
        # Process request
        response = await call_next(request)
        
        # Calculate processing time
        process_time = time.time() - start_time
        
        # Log successful request
        logger.info(
            "Request processed successfully",
            extra={
                'correlation_id': correlation_id,
                'request_path': request.url.path,
                'status_code': response.status_code,
                'response_time': process_time,
                'method': request.method,
                'service': 'fastapi-echo'
            }
        )
        
        # Add custom headers
        response.headers["X-Process-Time"] = str(process_time)
        response.headers["X-Correlation-ID"] = correlation_id
        
        return response
        
    except Exception as e:
        # Calculate processing time even for errors
        process_time = time.time() - start_time
        
        # Get status code from exception if available
        status_code = status.HTTP_500_INTERNAL_SERVER_ERROR
        if isinstance(e, HTTPException):
            status_code = e.status_code
        
        # Log error
        logger.error(
            "Request processing failed",
            extra={
                'correlation_id': correlation_id,
                'request_path': request.url.path,
                'error': str(e),
                'status_code': status_code,
                'response_time': process_time,
                'method': request.method,
                'service': 'fastapi-echo'
            }
        )
        
        if isinstance(e, HTTPException):
            return JSONResponse(
                status_code=e.status_code,
                content={"detail": e.detail}
            )
        raise

# Error demonstration endpoints
@app.get("/error/400")
async def bad_request():
    """Demo endpoint for 400 Bad Request"""
    raise HTTPException(
        status_code=status.HTTP_400_BAD_REQUEST,
        detail="Bad request demonstration"
    )

@app.get("/error/401")
async def unauthorized():
    """Demo endpoint for 401 Unauthorized"""
    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Unauthorized access demonstration"
    )

@app.get("/error/403")
async def forbidden():
    """Demo endpoint for 403 Forbidden"""
    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail="Forbidden access demonstration"
    )

@app.get("/error/404")
async def not_found():
    """Demo endpoint for 404 Not Found"""
    raise HTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        detail="Resource not found demonstration"
    )

@app.get("/error/500")
async def internal_server_error():
    """Demo endpoint for 500 Internal Server Error"""
    raise HTTPException(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        detail="Internal server error demonstration"
    )

@app.get("/error/503")
async def service_unavailable():
    """Demo endpoint for 503 Service Unavailable"""
    raise HTTPException(
        status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
        detail="Service unavailable demonstration"
    )

@app.api_route("/{path_name:path}", methods=["GET", "POST", "PUT", "DELETE", "PATCH", "HEAD", "OPTIONS"])
async def echo(request: Request, path_name: str) -> dict[str, Any]:
    # Get request headers
    headers = dict(request.headers)
    
    # Get request body
    body = None
    if request.method not in ["GET", "HEAD"]:
        try:
            body = await request.json()
        except:
            body = await request.body()
            body = body.decode() if body else None

    response = {
        "path": f"/{path_name}",
        "method": request.method,
        "headers": headers,
        "body": body
    }
    
    return response

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
