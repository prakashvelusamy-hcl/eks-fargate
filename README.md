# 🏢 Internal Employee Directory System

A lightweight, multi-tier **employee directory system** built for internal use by your organization. It enables employees to:

- 🔍 Search colleagues by **name** or **department**
- ✏️ Update their own contact information
- 💻 Use a modern **React web UI** with a **Flask backend API**
- 🔐 Securely store and retrieve database credentials from **AWS Secrets Manager**

---

## 🚀 Architecture Overview

User --> ALB --> Frontend (Fargate) --> Backend API (EC2) --> RDS (PostgreSQL/MySQL)
|
Secrets Manager


### 📦 Components

| Component         | Description                                                                 |
|------------------|-----------------------------------------------------------------------------|
| **Frontend**      | React SPA deployed on **AWS Fargate** (`frontend` namespace)                |
| **Backend API**   | Flask REST API on **EC2-backed EKS nodes** (`backend` namespace)            |
| **Database**      | Amazon RDS (**PostgreSQL** or **MySQL**)                                    |
| **Secrets**       | DB credentials managed in **AWS Secrets Manager**                           |
| **Ingress**       | ALB Ingress routes `/api/*` to backend, `/` to frontend                     |
| **Monitoring**    | Prometheus + Grafana dashboards for metrics and alerts                      |
| **Security**      | JWT-based authentication for `/api` endpoints                               |

---

## 🧱 Directory Structure

```
.
├── backend/               # Flask API backend
│   ├── app.py             # Main Flask application
│   ├── config.py          # App config, uses Secrets Manager
│   ├── models.py          # SQLAlchemy models
│   ├── routes.py          # API routes
│   ├── init_db.py         # DB init scripts
│   ├── Dockerfile         # Backend Dockerfile
│   └── requirements.txt   # Python dependencies
├── frontend/              # React frontend
│   ├── public/
│   │   └── index.html
│   ├── src/
│   │   ├── App.js
│   │   ├── index.js
│   │   ├── EmployeeList.js
│   │   └── EmployeeForm.js
│   ├── Dockerfile         # Frontend Dockerfile
│   ├── nginx.conf         # NGINX config for serving frontend
│   └── package.json       # Frontend dependencies
├── modules/               # Reusable Terraform modules
│   ├── terraform-aws-apps
│   ├── terraform-aws-eks
│   ├── terraform-aws-helm
│   ├── terraform-aws-iam
│   ├── terraform-aws-rds
│   └── terraform-aws-vpc
├── main.tf                # Root Terraform config
├── providers.tf           # Terraform providers
├── terraform.tfvars       # Terraform variables
├── outputs.tf             # Terraform outputs
├── variables.tf           # Input variables
└── backend.tf             # Terraform backend

⚙️ Deployment Steps
1. Infrastructure Provisioning (Terraform)

terraform init
terraform apply
Creates:

VPC, Subnets, IAM roles

EKS Cluster (EC2 & Fargate support)

RDS instance

Secrets Manager secret

2. Build and Push Docker Images

# Backend
cd backend
docker build -t <your-ecr-repo>/employee-backend .
docker push <your-ecr-repo>/employee-backend

# Frontend
cd frontend
docker build -t <your-ecr-repo>/employee-frontend .
docker push <your-ecr-repo>/employee-frontend
3. Deploy to Kubernetes

kubectl apply -f modules/terraform-aws-apps/backend/
kubectl apply -f modules/terraform-aws-apps/frontend/


4. ALB Ingress Controller Setup
Deploy ALB ingress controller via Helm

Configure ingress.yaml to route /api/* to backend and / to frontend

5. Secrets Manager Integration
Create a secret in AWS Secrets Manager with DB credentials

Bind IAM role to backend service account (IRSA)

Inject into backend pod via envFrom or valueFrom

🔐 Authentication
All /api routes are secured using JWT:

Login returns a token

Token must be sent in Authorization: Bearer <token> header for protected routes

🧪 API Endpoints
Method	Endpoint	Description
GET	/api/employees	Search employees
POST	/api/employees	Add new employee
PUT	/api/employees	Update own info
DELETE	/api/employees	Delete profile
POST	/api/login	Authenticate user