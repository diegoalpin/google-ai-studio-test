output "dev_service_url" {
  value = google_cloud_run_v2_service.dev.uri
}

output "prod_service_url" {
  value = google_cloud_run_v2_service.prod.uri
}

output "trigger_id" {
  value = google_cloudbuild_trigger.main.trigger_id
}

output "connection_id" {
  value = google_developer_connect_connection.main.id
}
