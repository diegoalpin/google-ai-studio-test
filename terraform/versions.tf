terraform {
  required_version = ">= 1.5.7"

  backend "gcs" {
    bucket = "tf-state-geekshacking-workshop-snake"
    prefix = "terraform/state/vibe-snake"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 7.20.0"
    }
  }
}
