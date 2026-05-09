provider "google" {
  project = var.project_id
  region  = var.region
}

# 1. Artifact Registry
resource "google_artifact_registry_repository" "main" {
  location      = var.region
  repository_id = "vibe-snake-repo"
  format        = "DOCKER"
  description   = "Docker repository for Vibe Snake services"
}

# 2. Developer Connect Connection
resource "google_developer_connect_connection" "main" {
  location      = var.region
  connection_id = "github-connection"

  github_config {
    github_app = "DEVELOPER_CONNECT"
    authorizer_credential {
      oauth_token_secret_version = "" # Manual authorization required
    }
  }

  lifecycle {
    ignore_changes = [github_config[0].authorizer_credential]
  }
}

# 3. Developer Connect Repository Link
resource "google_developer_connect_git_repository_link" "main" {
  location               = var.region
  parent_connection      = google_developer_connect_connection.main.connection_id
  clone_uri             = var.github_repo_uri
  git_repository_link_id = "vibe-snake-repo-link"
}

# 4. Service Accounts
resource "google_service_account" "build_sa" {
  account_id   = "vibe-snake-build-sa"
  display_name = "Cloud Build Service Account for Vibe Snake"
}

resource "google_service_account" "run_sa" {
  account_id   = "vibe-snake-run-sa"
  display_name = "Cloud Run Runtime Service Account for Vibe Snake"
}

# 5. IAM Permissions for Build SA
resource "google_project_iam_member" "build_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.build_sa.email}"
}

resource "google_project_iam_member" "build_ar_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.build_sa.email}"
}

resource "google_project_iam_member" "build_run_admin" {
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${google_service_account.build_sa.email}"
}

resource "google_project_iam_member" "build_sa_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.build_sa.email}"
}

# 6. Cloud Build Trigger
resource "google_cloudbuild_trigger" "main" {
  name     = "vibe-snake-push-trigger"
  location = var.region

  service_account = google_service_account.build_sa.id

  developer_connect_event_config {
    git_repository_link = google_developer_connect_git_repository_link.main.id
    push {
      branch = var.trigger_branch
    }
  }

  filename = "cloudbuild.yaml"

  substitutions = {
    _LOCATION   = var.region
    _REPO_NAME  = google_artifact_registry_repository.main.repository_id
    _IMAGE_NAME = var.service_name
  }
}

# 7. Cloud Run Services (Initial placeholder)
resource "google_cloud_run_v2_service" "dev" {
  name     = "${var.service_name}-dev"
  location = var.region

  template {
    service_account = google_service_account.run_sa.email
    containers {
      image = "gcr.io/cloudrun/hello" # Placeholder
      ports {
        container_port = 3000
      }
    }
  }
  
  ingress = "INGRESS_TRAFFIC_ALL"
}

resource "google_cloud_run_v2_service" "prod" {
  name     = "${var.service_name}-prod"
  location = var.region

  template {
    service_account = google_service_account.run_sa.email
    containers {
      image = "gcr.io/cloudrun/hello" # Placeholder
      ports {
        container_port = 3000
      }
    }
  }

  ingress = "INGRESS_TRAFFIC_ALL"
}

# Allow public access
resource "google_cloud_run_v2_service_iam_member" "dev_public" {
  location = google_cloud_run_v2_service.dev.location
  name     = google_cloud_run_v2_service.dev.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_v2_service_iam_member" "prod_public" {
  location = google_cloud_run_v2_service.prod.location
  name     = google_cloud_run_v2_service.prod.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
