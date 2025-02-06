output "dashboard_id" {
  description = "ID of the created Datadog dashboard"
  value       = datadog_dashboard.top5_paths.id
}

output "dashboard_url" {
  description = "URL of the created Datadog dashboard"
  value       = datadog_dashboard.top5_paths.url
}
