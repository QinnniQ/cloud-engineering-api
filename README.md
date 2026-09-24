# Cloud Engineering API

[![CI](https://github.com/QinnniQ/cloud-engineering-api/actions/workflows/ci.yml/badge.svg)](https://github.com/QinnniQ/cloud-engineering-api/actions/workflows/ci.yml)
[![AWS](https://img.shields.io/badge/AWS-EC2-orange)](#aws-deployment)
[![Terraform](https://img.shields.io/badge/Terraform-IaC-844FBA)](#terraform-infrastructure-as-code)
[![Docker](https://img.shields.io/badge/Docker-Containerized-2496ED)](#docker-deployment)
[![FastAPI](https://img.shields.io/badge/FastAPI-API-009688)](#application)
[![HTTPS](https://img.shields.io/badge/HTTPS-Let%27s%20Encrypt-blue)](#https--tls)

A hands-on cloud engineering portfolio project built to demonstrate practical AWS, Linux, networking, containerization, Infrastructure as Code, CI, DNS, TLS, reverse proxying, security, and operational troubleshooting.

The FastAPI application is intentionally small. The engineering work is in the infrastructure and delivery path around it.

**Live API:** https://api.nickcloud.dev  
**Swagger docs:** https://api.nickcloud.dev/docs

---

## Why This Project Exists

The goal was to take a minimal API and progressively evolve its deployment from a manually exposed development service into a more secure and reproducible cloud setup.

The project demonstrates that I can:

- deploy and operate Linux workloads on AWS EC2
- configure DNS, HTTPS, Nginx, and a custom domain
- containerize an application with Docker and Docker Compose
- separate public and private network tiers inside a custom VPC
- restrict SSH access with Security Groups
- use a public EC2 instance as a jump host to access a private instance
- define AWS infrastructure with Terraform
- validate Python, Docker, and Terraform automatically with GitHub Actions
- reason about security boundaries, failure modes, and infrastructure trade-offs

---

## Architecture

### Live Application

```text
Internet
   |
   v
api.nickcloud.dev
   |
   v
Cloudflare DNS
   |
   v
AWS Elastic IP
   |
   v
AWS Security Group
   |
   v
Nginx :443
TLS termination + reverse proxy
   |
   v
127.0.0.1:8000
   |
   v
Docker Compose
   |
   v
Uvicorn / FastAPI
```

The application container is not directly exposed to the internet. Nginx is the public application gateway and proxies HTTPS traffic to a localhost-only Docker port.

### Terraform Networking Lab

```text
AWS VPC 10.0.0.0/16
|
+-- Public subnet 10.0.1.0/24
|   |
|   +-- Internet Gateway
|   +-- Public route table
|   +-- Public EC2 / jump host
|       +-- public IP
|       +-- SSH restricted to trusted source IP
|
+-- Private subnet 10.0.2.0/24
    |
    +-- Private route table
    +-- no direct internet route
    +-- Private EC2
        +-- no public IP
        +-- SSH allowed only from public EC2 security group
```

The private instance was validated by connecting through the public EC2 jump host and confirming that it had no direct outbound internet path.

More detail: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)

---

## Technology Stack

| Area | Technologies |
|---|---|
| Cloud | AWS EC2, VPC, subnets, Internet Gateway, route tables, Security Groups, EBS, Elastic IP |
| Infrastructure as Code | Terraform |
| Containers | Docker, Docker Compose |
| CI | GitHub Actions |
| Application | Python, FastAPI, Uvicorn |
| Web / TLS | Nginx, Let's Encrypt, Certbot |
| DNS | Cloudflare DNS |
| OS / Operations | Ubuntu Linux, SSH, systemd, apt |
| Version Control | Git, GitHub, SSH authentication |

---

## Application

### Root endpoint

```http
GET /
```

```json
{
  "message": "Cloud Engineering API is running"
}
```

### Health endpoint

```http
GET /health
```

```json
{
  "status": "healthy"
}
```

### API documentation

FastAPI exposes Swagger documentation at:

```text
https://api.nickcloud.dev/docs
```

---

## AWS Deployment

The live application runs on Ubuntu EC2 in `eu-central-1` (Frankfurt).

The deployment includes:

- EC2 compute
- EBS-backed root storage
- Elastic IP for a stable DNS target
- Security Group rules for SSH, HTTP, and HTTPS
- Docker Engine and Docker Compose
- Nginx reverse proxy
- Let's Encrypt certificate management

The live EC2 deployment and the Terraform networking lab are intentionally documented as separate stages: the live service demonstrates operations, while the Terraform configuration demonstrates reproducible infrastructure design.

---

## Terraform Infrastructure as Code

Terraform in [`terraform/`](terraform/) defines a custom AWS network rather than relying on the default VPC.

Managed resources include:

- VPC (`10.0.0.0/16`)
- public subnet (`10.0.1.0/24`)
- private subnet (`10.0.2.0/24`)
- Internet Gateway
- public and private route tables
- route table associations
- separate public/private EC2 Security Groups
- public EC2 jump host
- private EC2 instance with no public IP

The private route table intentionally has no Internet Gateway or NAT route. This keeps the private tier isolated. A production workload requiring controlled outbound access could use a NAT Gateway or another egress design.

### Local Terraform workflow

```bash
cd terraform
terraform init
terraform fmt
terraform validate
terraform plan
```

Copy the example variables file before planning:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Then replace the example `trusted_ip` with your own public IPv4 address in `/32` notation.

`terraform.tfvars`, Terraform state, and `.terraform/` are deliberately excluded from Git.

---

## Docker Deployment

The API is packaged with a `Dockerfile` and run through Docker Compose.

```bash
docker compose up -d --build
```

The Compose configuration publishes the application only on the EC2 loopback interface:

```text
127.0.0.1:8000:8000
```

This means Uvicorn is not directly reachable from the public internet.

Useful operational commands:

```bash
docker compose ps
docker compose logs -f
docker compose down
```

---

## GitHub Actions CI

Every push to `main` and every pull request runs the CI workflow in [`.github/workflows/ci.yml`](.github/workflows/ci.yml).

The pipeline currently checks:

1. repository checkout
2. Python setup
3. dependency installation
4. FastAPI import validation
5. Docker image build
6. Terraform formatting
7. Terraform initialization without a backend
8. Terraform validation

This provides an automated quality gate for both application and infrastructure code.

---

## Networking & Security Decisions

- SSH to the public EC2 host is restricted to a trusted `/32` source IP.
- The private EC2 instance has no public IP.
- SSH to the private instance is allowed only from the public EC2 Security Group.
- The private subnet has no direct internet route.
- Port `8000` is not exposed publicly.
- Docker binds the API only to `127.0.0.1:8000`.
- Nginx is the only public application gateway.
- HTTPS protects public traffic.
- Private SSH keys, `.env` files, Terraform state, and `.tfvars` are excluded from Git.
- Terraform no longer depends on a developer-specific local AWS CLI profile, making the configuration more portable.

---

## HTTPS / TLS

HTTPS is provided by Let's Encrypt with Certbot and terminated by Nginx.

```text
Browser -> HTTPS :443 -> Nginx -> 127.0.0.1:8000 -> Docker -> FastAPI
```

Certificate renewal was validated with:

```bash
sudo certbot renew --dry-run
```

Nginx configuration can be checked with:

```bash
sudo nginx -t
```

---

## Design Evolution

The project deliberately records its progression rather than presenting only the final state.

```text
Stage 1
Internet -> EC2 :8000 -> Uvicorn -> FastAPI

Stage 2
Internet -> Nginx :80 -> Uvicorn :8000

Stage 3
Domain -> Cloudflare DNS -> Elastic IP -> Nginx + TLS -> FastAPI

Stage 4
Domain -> Nginx + TLS -> localhost -> Docker Compose -> FastAPI

Stage 5
Terraform -> custom VPC -> public/private subnets -> jump host/private host

Stage 6
Git push -> GitHub Actions -> Python + Docker + Terraform validation
```

This progression reflects the main engineering themes of the project: security, reproducibility, isolation, automation, and operational clarity.

---

## Repository Structure

```text
.
|-- .github/
|   `-- workflows/
|       `-- ci.yml
|-- docs/
|   `-- ARCHITECTURE.md
|-- terraform/
|   |-- main.tf
|   |-- variables.tf
|   |-- outputs.tf
|   `-- terraform.tfvars.example
|-- Dockerfile
|-- docker-compose.yml
|-- main.py
|-- requirements.txt
|-- .dockerignore
|-- .gitignore
`-- README.md
```

---

## What I Learned

The most useful part of this project was seeing how individual cloud concepts interact in a real deployment.

Examples include:

- why a public IP alone does not make a workload reachable
- how route tables, Internet Gateways, and Security Groups solve different networking problems
- why application ports should not necessarily be internet-facing
- how a jump host can provide controlled access to private resources
- why `terraform plan` must be inspected before applying changes
- how seemingly small Terraform changes can trigger resource replacement
- how Docker improves reproducibility but does not replace host-level networking and TLS configuration
- how CI can validate application and infrastructure code before deployment

---

## Possible Next Steps

This repository is complete as a focused cloud-engineering portfolio project. Natural production-oriented extensions would include:

- remote Terraform state with locking
- automated deployment after CI
- CloudWatch metrics and centralized logs
- multi-AZ design and load balancing
- managed database services
- an Azure implementation of the same architecture for cross-cloud comparison

These are intentionally presented as extensions rather than requirements for the current project.

---

## Recruiter Summary

This project demonstrates hands-on experience with AWS, Terraform, Docker, Linux, GitHub Actions, networking, TLS, DNS, and security controls around a live FastAPI service.

It was built iteratively, tested at each stage, and documented with the same emphasis on trade-offs and operational reasoning that I would bring to a junior Cloud, Platform, DevOps, or Infrastructure Engineering role.
