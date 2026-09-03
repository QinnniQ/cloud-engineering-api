# Cloud Engineering API

[![AWS](https://img.shields.io/badge/AWS-EC2-orange)](#aws-infrastructure)
[![FastAPI](https://img.shields.io/badge/FastAPI-API-009688)](#application)
[![Nginx](https://img.shields.io/badge/Nginx-Reverse%20Proxy-009639)](#nginx-reverse-proxy)
[![HTTPS](https://img.shields.io/badge/HTTPS-Let%27s%20Encrypt-blue)](#https--tls)
[![Linux](https://img.shields.io/badge/Linux-Ubuntu-informational)](#linux-service-management)

A hands-on cloud engineering portfolio project demonstrating practical deployment, Linux administration, networking, security, DNS, TLS, reverse proxying, and AWS fundamentals.

The application itself is intentionally simple. The focus is the infrastructure, deployment workflow, operational setup, and security decisions around it.

**Live API:** https://api.nickcloud.dev  
**Swagger docs:** https://api.nickcloud.dev/docs

---

## Project Purpose

This project is designed to showcase practical cloud engineering foundations to potential employers.

It demonstrates the ability to:

- provision and operate a Linux server in AWS
- configure SSH access securely
- deploy application code from GitHub
- manage Python environments and dependencies
- run a FastAPI application behind Uvicorn
- manage long-running services with systemd
- configure Nginx as a reverse proxy
- expose only required ports through AWS Security Groups
- assign and use an Elastic IP
- configure DNS through Cloudflare
- secure traffic with HTTPS/TLS
- automate certificate renewal with Certbot
- reason about public vs private network access
- document architecture and operational decisions clearly

Future stages will extend the project with:

- Docker
- Terraform
- GitHub Actions
- CI/CD
- CloudWatch monitoring
- infrastructure as code
- Azure deployment

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
                    │              │
                    │              │
                 SSH :22        HTTPS :443
              trusted IP only     public
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
                               Uvicorn
                                   │
                                   ▼
                               FastAPI
                                   │
                                   ▼
                        systemd-managed service
```

The FastAPI application is **not publicly exposed on port 8000**.

Nginx is the only public web entry point and forwards requests internally to Uvicorn over localhost.

---

## Technology Stack

### Cloud

- AWS EC2
- AWS Elastic IP
- AWS Security Groups
- AWS EBS
- Frankfurt region (`eu-central-1`)

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

### Linux / Operations

- Ubuntu Linux
- SSH
- systemd
- apt
- virtual environments
- process and service management

### Version Control

- Git
- GitHub
- SSH-based GitHub authentication

### TLS

- Let’s Encrypt
- Certbot
- automatic certificate renewal

---

## Application

The API is intentionally minimal so the project can focus on cloud engineering and infrastructure.

### Root Endpoint

```http
GET /
```

Response:

```json
{
  "message": "Cloud Engineering API is running"
}
```

### Health Endpoint

```http
GET /health
```

Response:

```json
{
  "status": "healthy"
}
```

### Interactive API Documentation

FastAPI automatically exposes Swagger documentation at:

```text
https://api.nickcloud.dev/docs
```

---

## AWS Infrastructure

The application is deployed on an Ubuntu EC2 instance in:

```text
eu-central-1
Europe (Frankfurt)
```

Current instance configuration includes:

- Ubuntu Linux
- `t3.micro`
- EBS root volume
- public Elastic IP
- AWS Security Group
- SSH key-based authentication

The assigned Elastic IP is:

```text
18.195.59.95
```

This provides a stable public address for DNS.

---

## Security Group Rules

Current inbound access is intentionally minimal:

```text
SSH
Port: 22
Source: trusted IP only
```

```text
HTTP
Port: 80
Source: 0.0.0.0/0
```

```text
HTTPS
Port: 443
Source: 0.0.0.0/0
```

Port `8000` is not publicly exposed.

The application is reachable internally through:

```text
127.0.0.1:8000
```

This means external traffic must pass through Nginx.

---

## DNS

The project uses:

```text
api.nickcloud.dev
```

DNS is managed through Cloudflare.

The DNS flow is:

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

The DNS record is configured as an `A` record pointing to the EC2 Elastic IP.

---

## HTTPS / TLS

The API is secured with HTTPS using a certificate issued by Let’s Encrypt.

TLS termination is handled by Nginx.

Current flow:

```text
Browser
   │
   ▼
HTTPS :443
   │
   ▼
Nginx
   │
   ▼
127.0.0.1:8000
   │
   ▼
FastAPI
```

The certificate was installed with Certbot.

Certificate files are stored at:

```text
/etc/letsencrypt/live/api.nickcloud.dev/
```

Certificate renewal is automated.

A renewal test was verified successfully using:

```bash
sudo certbot renew --dry-run
```

Nginx configuration was also validated using:

```bash
sudo nginx -t
```

---

## Nginx Reverse Proxy

Nginx acts as the public-facing web server.

Requests to:

```text
https://api.nickcloud.dev
```

are forwarded internally to:

```text
http://127.0.0.1:8000
```

Example reverse proxy configuration:

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

This setup separates the public web layer from the application server.

---

## Linux Service Management

The FastAPI application is managed with systemd.

Service name:

```text
cloud-api.service
```

The service:

- runs as the `ubuntu` user
- starts automatically after reboot
- restarts automatically if the process fails
- runs Uvicorn from the project virtual environment
- uses the application repository as its working directory

Useful operational commands:

```bash
sudo systemctl status cloud-api
sudo systemctl start cloud-api
sudo systemctl stop cloud-api
sudo systemctl restart cloud-api
sudo systemctl enable cloud-api
```

The service has been tested successfully across an EC2 reboot.

---

## Deployment Workflow

Current manual deployment workflow:

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
Python virtual environment
      │
      ▼
systemd restart
      │
      ▼
Nginx
      │
      ▼
Public HTTPS API
```

GitHub is treated as the source of truth for application code.

Future iterations will replace the manual deployment steps with GitHub Actions and CI/CD.

---

## Local Development

Clone the repository:

```bash
git clone git@github.com:QinnniQ/cloud-engineering-api.git
```

Move into the project:

```bash
cd cloud-engineering-api
```

### Windows

```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
```

### Linux

```bash
python3 -m venv .venv
source .venv/bin/activate
```

Install dependencies:

```bash
pip install -r requirements.txt
```

Run locally:

```bash
uvicorn main:app --reload
```

Open:

```text
http://127.0.0.1:8000
```

Swagger:

```text
http://127.0.0.1:8000/docs
```

---

## Security Decisions

- SSH is restricted to a trusted IP.
- Uvicorn runs on port `8000`, but that port is not publicly exposed.
- Only standard public web ports `80` and `443` are exposed.
- Production-facing traffic is secured with HTTPS.
- EC2 private SSH keys are not committed to Git.
- GitHub authentication uses SSH keys.
- `.env` files are excluded through `.gitignore`.
- The application runs as a non-root Linux user.

---

## Key Cloud Engineering Concepts Practiced

### Compute
AWS EC2 provides the virtual machine that runs the application.

### Storage
The EC2 instance uses an EBS root volume.

### Networking
The project uses and demonstrates:

- public IPv4
- private IPv4
- Elastic IPs
- TCP ports
- Security Groups
- DNS
- HTTP
- HTTPS
- localhost networking
- reverse proxying

### Linux
The project uses:

- SSH
- package management
- processes
- services
- systemd
- file paths
- virtual environments
- service lifecycle management

### Security
The project demonstrates:

- restricted SSH access
- least-exposure networking
- TLS encryption
- separation of public and internal ports
- key-based authentication

### Operations
The project demonstrates:

- service health checks
- reboot persistence
- Nginx validation
- certificate renewal testing
- manual deployment workflows

---

## Design Evolution

### Initial Version

```text
Internet
   │
   ▼
EC2 :8000
   │
   ▼
Uvicorn
   │
   ▼
FastAPI
```

### Reverse Proxy Version

```text
Internet
   │
   ▼
Nginx :80
   │
   ▼
Uvicorn :8000
   │
   ▼
FastAPI
```

### Current Version

```text
Internet
   │
   ▼
api.nickcloud.dev
   │
   ▼
Cloudflare DNS
   │
   ▼
Elastic IP
   │
   ▼
HTTPS :443
   │
   ▼
Nginx + TLS
   │
   ▼
Uvicorn :8000
   │
   ▼
FastAPI
```

This progression demonstrates how the architecture evolved as security, reliability, and operational requirements increased.

---

## Current Project Status

### Completed

- [x] Create FastAPI application
- [x] Create GitHub repository
- [x] Configure GitHub SSH authentication
- [x] Launch AWS EC2 instance
- [x] Configure SSH access
- [x] Deploy project from GitHub to EC2
- [x] Configure Python virtual environment
- [x] Configure Uvicorn
- [x] Configure AWS Security Group
- [x] Configure systemd service
- [x] Enable automatic service restart
- [x] Verify service survives EC2 reboot
- [x] Install and configure Nginx
- [x] Configure reverse proxy
- [x] Remove public access to port 8000
- [x] Allocate and associate Elastic IP
- [x] Register `nickcloud.dev`
- [x] Configure Cloudflare DNS
- [x] Configure `api.nickcloud.dev`
- [x] Install Let’s Encrypt certificate
- [x] Enable HTTPS
- [x] Configure automatic certificate renewal
- [x] Verify certificate renewal with dry run
- [x] Validate Nginx configuration

### Planned

- [ ] Containerize application with Docker
- [ ] Add Docker Compose where useful
- [ ] Define infrastructure with Terraform
- [ ] Add GitHub Actions
- [ ] Build CI/CD pipeline
- [ ] Add automated deployment
- [ ] Add AWS CloudWatch monitoring
- [ ] Add application logging
- [ ] Add infrastructure architecture diagram
- [ ] Recreate selected infrastructure in Azure
- [ ] Compare AWS and Azure service mappings

---

## Upcoming Architecture

```text
                         GitHub
                            │
                            ▼
                    GitHub Actions
                            │
                            ▼
                         CI/CD
                            │
                            ▼
                       Terraform
                       /       \
                      ▼         ▼
                    AWS       Azure
                     │           │
                     ▼           ▼
                   Docker     Docker
                     │           │
                     ▼           ▼
                 Application Application
                     │           │
                     ▼           ▼
               Monitoring   Monitoring
```

---

## What This Project Demonstrates to Employers

This repository is intended to show more than familiarity with AWS service names.

It demonstrates practical experience with:

- deploying and administering cloud compute
- Linux server operations
- public/private network design
- Security Group configuration
- DNS and domain configuration
- reverse proxy architecture
- TLS certificates
- service management
- Git-based deployment
- cloud security fundamentals
- operational troubleshooting
- architecture evolution
- documenting technical decisions

The project is intentionally developed incrementally so each infrastructure decision can be understood, tested, and documented rather than hidden behind a fully managed deployment platform.

---

## Repository Roadmap

1. Dockerize the FastAPI application
2. Replace manual infrastructure creation with Terraform
3. Add GitHub Actions
4. Implement CI/CD
5. Add monitoring and logging with CloudWatch
6. Recreate a comparable deployment in Azure
7. Add a polished architecture diagram and final portfolio case study

---

## Repository Purpose

This repository is part of a broader cloud engineering portfolio.

The goal is to evolve a simple application into a production-style, multi-cloud-aware deployment while demonstrating the infrastructure, security, automation, networking, and operational skills expected in junior cloud, platform, and DevOps-adjacent engineering roles.
