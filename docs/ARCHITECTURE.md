# Architecture Notes

This document separates the two architectural concerns demonstrated by the repository: the live application deployment and the Terraform networking lab.

## 1. Live application path

```text
Client
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
EC2 Security Group
  |
  v
Nginx :443
  |  TLS termination
  |  reverse proxy
  v
127.0.0.1:8000
  |
  v
Docker Compose
  |
  v
Uvicorn
  |
  v
FastAPI
```

### Key decisions

- Nginx is the only public application gateway.
- The application port is bound to the loopback interface rather than all interfaces.
- TLS terminates at Nginx using a Let's Encrypt certificate managed with Certbot.
- DNS resolves the public hostname to a stable AWS Elastic IP.
- Docker Compose describes the application runtime declaratively.

## 2. Terraform VPC lab

```text
VPC 10.0.0.0/16
|
+-- Public subnet 10.0.1.0/24
|   |
|   +-- route 0.0.0.0/0 -> Internet Gateway
|   +-- public EC2 instance
|       +-- public IPv4 address
|       +-- SSH from trusted /32 only
|
+-- Private subnet 10.0.2.0/24
    |
    +-- local VPC route only
    +-- private EC2 instance
        +-- no public IPv4 address
        +-- SSH only from public EC2 Security Group
```

### Validation performed

The public EC2 instance was reachable from the trusted client over SSH and had outbound internet access through the Internet Gateway.

The private EC2 instance was then reached through the public host as an SSH jump host. Its address was confirmed to be inside the private subnet and a direct outbound request to the public internet failed because the subnet intentionally has no NAT or Internet Gateway route.

## 3. Security model

The project uses several independent controls rather than treating any one control as sufficient:

- VPC and subnet placement define network boundaries.
- Route tables determine which network paths exist.
- Security Groups restrict permitted traffic.
- Public/private IP assignment determines direct addressability.
- Nginx limits the externally exposed application surface.
- Docker publishes the API only to localhost on the host.
- SSH keys provide host authentication.
- Git ignore rules prevent local secrets, Terraform variables, and state from being committed.

## 4. Why there is no NAT Gateway

A NAT Gateway would allow workloads in the private subnet to initiate outbound internet connections while remaining unreachable directly from the internet.

It is intentionally omitted from this lab because the isolation behavior was the learning objective and a continuously running NAT Gateway would add unnecessary cost. In a production environment, outbound requirements would be assessed and a NAT Gateway, VPC endpoints, proxy, or another controlled egress design selected accordingly.

## 5. CI architecture

```text
Push / Pull Request
        |
        v
GitHub Actions
        |
        +-- install Python dependencies
        +-- validate FastAPI import
        +-- build Docker image
        +-- terraform fmt -check
        +-- terraform init -backend=false
        `-- terraform validate
```

The workflow intentionally performs validation only. Deployment credentials are not required for pull requests, keeping CI separate from privileged delivery operations.

## 6. Production extensions

A larger production architecture could evolve toward:

```text
Internet
  |
  v
Load Balancer
  |
  +---- App instance / task (AZ A)
  |
  `---- App instance / task (AZ B)
            |
            v
      Private database tier
```

Additional production capabilities could include remote Terraform state, least-privilege CI/CD identity, automated deployment, CloudWatch logging and alarms, multi-AZ compute, and a managed database.
