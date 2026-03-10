# Lesson 5 — Terraform Infrastructure on AWS

This project provisions core AWS infrastructure using Terraform with a modular approach. It covers remote state management, networking, and container registry setup.

---

## Project Structure

```
lesson-5/
├── main.tf              # Root module — wires all child modules together
├── backend.tf           # Remote backend configuration (S3 + DynamoDB)
├── outputs.tf           # Aggregated outputs from all modules
├── README.md
└── modules/
    ├── s3-backend/      # S3 bucket + DynamoDB table for Terraform state
    │   ├── s3.tf
    │   ├── dynamodb.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── vpc/             # VPC, subnets, IGW, NAT Gateways, route tables
    │   ├── vpc.tf
    │   ├── routes.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── ecr/             # ECR repository with lifecycle & access policy
        ├── ecr.tf
        ├── variables.tf
        └── outputs.tf
```

---

## Modules

### `s3-backend`
Creates the infrastructure required for remote Terraform state storage:
- **S3 Bucket** — stores `terraform.tfstate` with versioning and AES-256 encryption enabled. Public access is fully blocked.
- **DynamoDB Table** — provides state locking via `LockID` attribute (PAY_PER_REQUEST billing) with Point-in-Time Recovery enabled.

**Key variables:**
| Variable | Default | Description |
|---|---|---|
| `bucket_name` | — | Globally unique S3 bucket name |
| `table_name` | `terraform-locks` | DynamoDB table name |

---

### `vpc`
Creates a production-ready network with high availability across 3 Availability Zones:
- **VPC** — custom CIDR, DNS hostnames and resolution enabled.
- **3 Public Subnets** — `10.0.1–3.0/24`, each in a separate AZ, with `map_public_ip_on_launch = true`.
- **3 Private Subnets** — `10.0.4–6.0/24`, each in a separate AZ, without public IP assignment.
- **Internet Gateway** — attached to the VPC for outbound public traffic.
- **3 NAT Gateways** — one per public subnet/AZ for resilient outbound access from private subnets.
- **Route Tables** — one shared public RT (default route → IGW); one private RT per AZ (default route → NAT GW).

**Key variables:**
| Variable | Default | Description |
|---|---|---|
| `vpc_cidr_block` | `10.0.0.0/16` | VPC CIDR |
| `public_subnets` | `["10.0.1.0/24", ...]` | List of public subnet CIDRs |
| `private_subnets` | `["10.0.4.0/24", ...]` | List of private subnet CIDRs |
| `availability_zones` | `["us-west-2a", ...]` | AZ list |
| `vpc_name` | `lesson-5-vpc` | Name prefix for resources |

---

### `ecr`
Creates an Elastic Container Registry repository for Docker images:
- **ECR Repository** — AES-256 encrypted, configurable tag mutability.
- **Image Scanning** — `scan_on_push` enabled by default (vulnerability scanning on each push).
- **Lifecycle Policy** — automatically removes untagged images older than 30 days and keeps only the last 10 versioned (`v*`) images.
- **Repository Policy** — grants the current AWS account full access to push, pull, and manage images.

**Key variables:**
| Variable | Default | Description |
|---|---|---|
| `ecr_name` | — | Repository name |
| `scan_on_push` | `true` | Enable image scanning |
| `image_tag_mutability` | `MUTABLE` | `MUTABLE` or `IMMUTABLE` |

---

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.0
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) configured with valid credentials
- AWS account with permissions for S3, DynamoDB, VPC, and ECR

---

## Usage

### First Run (bootstrap remote state)

Because the S3 bucket and DynamoDB table don't exist yet, run Terraform locally for the first time:

```bash
# 1. Initialize with local state
terraform init

# 2. Create only the backend resources first
terraform apply -target=module.s3_backend
```

After the bucket and table are created, enable the remote backend:

```bash
# 3. Uncomment the backend block in backend.tf and set your bucket name
# 4. Migrate local state to S3
terraform init -migrate-state
```

### Regular Workflow

```bash
# Initialize (or re-initialize after backend change)
terraform init

# Preview changes
terraform plan

# Apply all changes
terraform apply

# Destroy all resources (⚠️ deletes everything including state backend!)
terraform destroy
```

### Push Docker Image to ECR

After `terraform apply`, use the `ecr_repository_url` output:

```bash
# Authenticate Docker to ECR
aws ecr get-login-password --region us-west-2 | \
  docker login --username AWS --password-stdin <ecr_repository_url>

# Tag and push your image
docker tag my-app:latest <ecr_repository_url>:latest
docker push <ecr_repository_url>:latest
```

---

## ⚠️ Cost Warning

This infrastructure creates **billable AWS resources**, including:
- NAT Gateways (~$0.045/hour each × 3 = ~$97/month)
- Elastic IPs (free while attached; charged if unattached)
- S3 storage and requests
- DynamoDB read/write capacity

**Always run `terraform destroy` after testing to avoid unexpected charges.**

---

## ⚠️ Destroy Order Note

Running `terraform destroy` will **also delete** the S3 bucket and DynamoDB table used for state storage. After a full destroy, the next `terraform init` will start with local state again (step back to the bootstrap flow above).
