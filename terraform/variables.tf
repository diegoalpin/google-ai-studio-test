variable "project_id" {
  type        = string
  description = "The GCP project ID"
  default     = "geekshacking-workshop-snake"
}

variable "region" {
  type        = string
  description = "The GCP region"
  default     = "us-central1"
}

variable "service_name" {
  type        = string
  description = "The base name of the Cloud Run service"
  default     = "vibe-snake"
}

variable "github_repo_uri" {
  type        = string
  description = "The URI of the GitHub repository"
  default     = "https://github.com/diegoalpin/google-ai-studio-test.git"
}

variable "trigger_branch" {
  type        = string
  description = "The branch to trigger the build"
  default     = "^main$"
}
