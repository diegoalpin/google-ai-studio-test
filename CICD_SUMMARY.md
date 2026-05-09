# Project Vibe Snake: CI/CD Architecture & Implementation Summary

This document summarizes the transition from manual deployment scripts to a production-grade, automated CI/CD pipeline on Google Cloud.

## 🏗️ Architecture Overview

The pipeline implements a **Trunk-Based Development** pattern, ensuring that every change pushed to the `main` branch is verified and deployed automatically.

### 1. Source Control & Connectivity
- **GitHub Integration**: Connected via **Developer Connect**, providing a secure, identity-based link between GitHub and Google Cloud without using long-lived personal access tokens.
- **Trigger**: A Cloud Build trigger monitors the `main` branch for any new pushes.

### 2. CI/CD Pipeline (Cloud Build)
The pipeline is defined in `cloudbuild.yaml` and consists of the following sequential stages:
1.  **Verification**: Runs `npm install` followed by `npm run lint` (TypeScript type-checking) to ensure code quality before building.
2.  **Containerization**: Builds a multi-stage Docker image optimized for production.
3.  **Artifact Storage**: Pushes the image to **Artifact Registry**, tagging it with both the unique `COMMIT_SHA` (for traceability) and `latest`.
4.  **Deployment**: Performs an atomic deployment to two distinct Cloud Run environments:
    - `vibe-snake-dev`: For immediate preview and testing.
    - `vibe-snake-prod`: For production traffic.

### 3. Infrastructure as Code (Terraform)
The entire infrastructure is managed as code in the `terraform/` directory, ensuring reproducibility and environment consistency.
- **State Management**: Remote state is stored in a versioned GCS bucket (`tf-state-geekshacking-workshop-snake`).
- **Identity & Access (IAM)**:
    - `vibe-snake-build-sa`: A dedicated service account for Cloud Build with minimal required permissions (AR Writer, Run Admin, Logging).
    - `vibe-snake-run-sa`: A dedicated runtime service account for Cloud Run.

---

## 🚀 Implementation Journey (Sequential Steps)

### Phase 1: Research & Discovery
- Analyzed the existing `deploy.sh` script to understand current deployment requirements (Port 3000, Artifact Registry, etc.).
- Identified the application archetype as a Node.js/React full-stack app.

### Phase 2: Design
- Defined a dual-environment strategy (Dev/Prod).
- Selected **Trunk-Based Push-to-Deploy** as the primary delivery pattern.

### Phase 3: Infrastructure Provisioning
- **Terraform Setup**: Initialized Terraform with a GCS backend.
- **GCP API Enablement**: Enabled `developerconnect.googleapis.com`, `secretmanager.googleapis.com`, and `run.googleapis.com`.
- **Resource Creation**: Provisioned the Artifact Registry, Service Accounts, and Cloud Run services.
- **GitHub Handshake**: Created the Developer Connect connection, which required a manual OAuth authorization and GitHub App installation to establish trust.

### Phase 4: Pipeline Implementation
- Authored the `cloudbuild.yaml` file incorporating the requested linting and dual-deployment steps.
- Resolved permission issues where the Cloud Build service account needed `developerconnect.readTokenAccessor` to pull code from GitHub.

### Phase 5: Verification & Deployment
- Committed the configuration to the repository.
- Manually triggered the first build to verify the end-to-end flow.

---

## 💡 Key Learnings & Troubleshooting
- **Permission Elevation**: The Developer Connect service agent requires `roles/secretmanager.admin` to store OAuth tokens securely in Secret Manager during the initial setup.
- **Provider Versioning**: Using Google Provider `v7.20.0+` is essential for utilizing the latest Developer Connect resources in Terraform.
- **Large Files**: Avoid committing `.terraform/` binaries to Git, as they exceed GitHub's file size limits. Always use a `.gitignore`.

---

## 🔗 Environment URLs
- **Dev:** [https://vibe-snake-dev-3iyuqidrva-uc.a.run.app](https://vibe-snake-dev-3iyuqidrva-uc.a.run.app)
- **Prod:** [https://vibe-snake-prod-3iyuqidrva-uc.a.run.app](https://vibe-snake-prod-3iyuqidrva-uc.a.run.app)
