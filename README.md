# Cloud Engineering API

[![AWS](https://img.shields.io/badge/AWS-EC2-orange)](#aws-infrastructure)
[![Docker](https://img.shields.io/badge/Docker-Containerized-2496ED)](#docker-deployment)
[![FastAPI](https://img.shields.io/badge/FastAPI-API-009688)](#application)
[![Nginx](https://img.shields.io/badge/Nginx-Reverse%20Proxy-009639)](#nginx-reverse-proxy)
[![HTTPS](https://img.shields.io/badge/HTTPS-Let%27s%20Encrypt-blue)](#https--tls)
[![Linux](https://img.shields.io/badge/Linux-Ubuntu-informational)](#linux--operations)

A hands-on cloud engineering portfolio project demonstrating practical cloud deployment, Linux administration, containerization, networking, security, DNS, TLS, reverse proxying, and AWS fundamentals.

The application itself is intentionally simple. The focus is the infrastructure, deployment workflow, operational setup, security decisions, and progressive evolution toward an automated multi-cloud architecture.

**Live API:** https://api.nickcloud.dev  
**Swagger docs:** https://api.nickcloud.dev/docs

---

## What This Project Demonstrates

This project is designed to showcase practical cloud engineering foundations to potential employers.

It demonstrates experience with:

- AWS EC2 and EBS
- Elastic IP addressing
- AWS Security Groups
- Ubuntu Linux administration
- SSH key-based access
- Git and GitHub
- Docker images and containers
- Docker Compose
- FastAPI and Uvicorn
- Nginx reverse proxying
- systemd service management
- Cloudflare DNS
- HTTPS/TLS
- Let's Encrypt and Certbot
- certificate renewal
- public vs private network exposure
- application health checks
- deployment troubleshooting
- architecture evolution and documentation

Future stages will add Terraform, GitHub Actions, CI/CD, AWS CloudWatch, structured logging, infrastructure as code, Azure deployment, and cross-cloud architecture comparison.

---

## Current Architecture

```text
                         Internet
                            │
                            ▼
                  https://api.nickcloud.dev
                            │
                            ▼
                    Cloudflare DNS
                            │
                            ▼
                    AWS Elastic IP
                      18.195.59.95
                            │
                            ▼
                 AWS Security Group
                  │                │
               SSH :22         HTTPS :443
            trusted IP only       public
                                    │
                                    ▼
                                  Nginx
                          TLS termination
                           reverse proxy
                                    │
                                    ▼
                           127.0.0.1:8000
                                    │
                                    ▼
                             Docker Engine
                                    │
                                    ▼
                         cloud-api-container
                                    │
                                    ▼
                                  Uvicorn
                                    │
                                    ▼
                                  FastAPI
```

The FastAPI application is not exposed directly to the public internet. Nginx is the public-facing web server. It terminates TLS and forwards requests to the Dockerized application on localhost.

---

## Technology Stack

### Cloud
- AWS EC2
- AWS Elastic IP
- AWS Security Groups
- AWS EBS
- AWS Frankfurt region (`eu-central-1`)

### Containers
- Docker Engine
- Dockerfile
- Docker Compose
- container restart policies
- localhost-only port publishing

### Networking & Web
- IPv4
- DNS
- TCP ports
- HTTP / HTTPS
- Nginx
- reverse proxying
- TLS
- Cloudflare DNS

### Application
- Python
- FastAPI
- Uvicorn
- Pydantic

### Linux & Operations
- Ubuntu Linux
- SSH
- systemd
- apt
- process and service management

### Version Control
- Git
- GitHub
- SSH-based GitHub authentication

### TLS
- Let's Encrypt
- Certbot
- automatic certificate renewal

---

## Application

### Root Endpoint

```http
GET /
```

```json
{
  "message": "Cloud Engineering API is running"
}
```

### Health Endpoint

```http
GET /health
```

```json
{
  "status": "healthy"
}
```

### API Documentation

```text
https://api.nickcloud.dev/docs
```

---

## AWS Infrastructure

The application is deployed to an Ubuntu EC2 instance in `eu-central-1` (Europe, Frankfurt).

Current configuration:

- Ubuntu Linux
- `t3.micro`
- EBS root volume
- Elastic IP
- AWS Security Group
- SSH key-based authentication
- Docker Engine
- Nginx

Elastic IP:

```text
18.195.59.95
```

This gives DNS a stable public destination even when the EC2 instance is restarted.

---

## Security Group Rules

Inbound access is deliberately limited.

```text
SSH  :22  -> trusted IP only
HTTP :80  -> public
HTTPS:443 -> public
```

Port `8000` is not exposed through the AWS Security Group.

The Docker container is also published only on the EC2 loopback interface:

```text
127.0.0.1:8000
```

This creates two layers preventing direct public access to Uvicorn.

---

## Docker Deployment

The application is packaged using Docker.

Build locally:

```bash
docker build -t cloud-engineering-api .
```

Run locally:

```bash
docker run --rm -p 8000:8000 cloud-engineering-api
```

On EC2, the application port is bound only to localhost:

```bash
docker run -d \
  --name cloud-api-container \
  --restart unless-stopped \
  -p 127.0.0.1:8000:8000 \
  cloud-engineering-api
```

The container uses the `unless-stopped` restart policy so Docker restarts it after host reboots or unexpected exits unless it was intentionally stopped.

---

## Docker Compose

The runtime configuration is represented declaratively in `docker-compose.yml`.

Start or rebuild:

```bash
docker compose up -d --build
```

Check status:

```bash
docker compose ps
```

View logs:

```bash
docker compose logs -f
```

Stop:

```bash
docker compose down
```

This replaces an imperative `docker run` command with a reproducible configuration stored in Git.

---

## DNS

The public API uses `api.nickcloud.dev` with DNS managed through Cloudflare.

```text
api.nickcloud.dev
        │
        ▼
Cloudflare DNS
        │
        ▼
18.195.59.95
        │
        ▼
AWS EC2
```

An `A` record maps the hostname to the EC2 Elastic IP.

---

## HTTPS / TLS

HTTPS is provided using a Let's Encrypt certificate installed with Certbot. TLS terminates at Nginx.

```text
Browser -> HTTPS :443 -> Nginx -> 127.0.0.1:8000 -> Docker container
```

Certificate renewal is automated and was validated with:

```bash
sudo certbot renew --dry-run
```

Nginx configuration validation:

```bash
sudo nginx -t
```

---

## Nginx Reverse Proxy

Nginx is the public-facing web server. Requests to `https://api.nickcloud.dev` are proxied internally to `http://127.0.0.1:8000`.

```nginx
server {
    listen 80;
    server_name api.nickcloud.dev;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Certbot extends the Nginx configuration with TLS support.

---

## Linux & Operations

Practiced operational tasks include:

- SSH access
- package installation with `apt`
- service inspection with `systemctl`
- process management
- Nginx validation and reloads
- Docker daemon management
- Docker group permissions
- OS package upgrades
- EC2 reboot testing
- container restart testing
- service health verification

The original deployment used a custom systemd service for Uvicorn. After containerization, that service was disabled and Docker became responsible for the application process lifecycle. Nginx and Docker themselves remain managed by systemd.

---

## Deployment Workflow

```text
Local VS Code
      │
      ▼
Git commit
      │
      ▼
GitHub
      │
      ▼
EC2 git pull
      │
      ▼
Docker build
      │
      ▼
Docker Compose
      │
      ▼
Container
      │
      ▼
Nginx
      │
      ▼
HTTPS API
```

The next iteration will automate this process using GitHub Actions.

---

## Security Decisions

- SSH is restricted to a trusted source IP.
- GitHub and EC2 authentication use SSH keys.
- Private SSH keys are never committed to Git.
- `.env` files are excluded from source control.
- Port `8000` is not publicly permitted by the AWS Security Group.
- Docker publishes port `8000` only to `127.0.0.1`.
- Nginx is the only public application gateway.
- HTTPS encrypts public traffic.
- TLS certificates renew automatically.
- The application does not run directly as `root`.

---

## Design Evolution

### Stage 1 — Direct Application Exposure

```text
Internet -> EC2 :8000 -> Uvicorn -> FastAPI
```

### Stage 2 — Reverse Proxy

```text
Internet -> Nginx :80 -> Uvicorn :8000
```

### Stage 3 — DNS + HTTPS

```text
api.nickcloud.dev -> Cloudflare DNS -> Elastic IP -> Nginx + TLS -> Uvicorn
```

### Stage 4 — Containerized Runtime

```text
api.nickcloud.dev
   │
   ▼
Cloudflare DNS
   │
   ▼
AWS EC2
   │
   ▼
Nginx + TLS
   │
   ▼
127.0.0.1:8000
   │
   ▼
Docker
   │
   ▼
Uvicorn
   │
   ▼
FastAPI
```

This progression documents how the architecture became progressively more secure, portable, reproducible, and operationally robust.

---

## Current Project Status

### Completed

- [x] FastAPI application
- [x] GitHub repository
- [x] GitHub SSH authentication
- [x] AWS EC2 instance
- [x] SSH access
- [x] EBS-backed Linux host
- [x] Security Group configuration
- [x] systemd-managed initial application deployment
- [x] Nginx reverse proxy
- [x] private application port
- [x] Elastic IP
- [x] `nickcloud.dev` domain
- [x] Cloudflare DNS
- [x] `api.nickcloud.dev`
- [x] Let's Encrypt TLS certificate
- [x] Certbot automatic renewal
- [x] reboot testing
- [x] Dockerfile
- [x] `.dockerignore`
- [x] local Docker image build
- [x] local Docker container testing
- [x] Docker Engine on EC2
- [x] Dockerized production runtime
- [x] localhost-only Docker port binding
- [x] Docker restart policy
- [x] Docker Compose configuration

### Planned

- [ ] Terraform
- [ ] Infrastructure as Code
- [ ] GitHub Actions
- [ ] automated CI/CD
- [ ] AWS CloudWatch monitoring
- [ ] centralized application logs
- [ ] production architecture diagram
- [ ] Azure deployment
- [ ] AWS ↔ Azure service comparison
- [ ] final employer-facing case study

---

## What This Shows Employers

This repository demonstrates practical experience rather than only theoretical familiarity with cloud terminology.

It shows hands-on work with cloud compute, Linux administration, containerization, application deployment, network security, DNS, TLS, reverse proxies, public/private network boundaries, Git-based release workflows, service lifecycle management, troubleshooting, architecture evolution, and technical documentation.

---

## Roadmap

1. Standardize container deployment with Docker Compose
2. Define AWS infrastructure with Terraform
3. Add GitHub Actions
4. Automate CI/CD
5. Add CloudWatch monitoring and logging
6. Recreate the deployment in Azure
7. Add an employer-facing architecture diagram and final case study

---

## Repository Purpose

This repository is part of a broader cloud engineering portfolio.

The goal is to evolve a simple API into a polished, production-style, multi-cloud-aware deployment while demonstrating the infrastructure, security, automation, networking, containerization, and operational skills expected in junior cloud, platform, and DevOps-adjacent engineering roles.
