# Cloud Engineering API

A small FastAPI service used as a hands-on cloud engineering project.

## Features

- FastAPI REST API
- Health check endpoint
- Automatic Swagger documentation
- Local development with Uvicorn
- AWS EC2 deployment
- Linux service management
- Networking and security group configuration

## Endpoints

### Root

GET /

Returns:

```json
{
  "message": "Cloud Engineering API is running"
}