output "public_ip" {
  description = "Public IP address of the monitoring server"
  value       = aws_eip.monitoring_eip.public_ip
}

output "grafana_url" {
  description = "URL to access Grafana"
  value       = "http://${aws_eip.monitoring_eip.public_ip}:3000"
}

output "prometheus_url" {
  description = "URL to access Prometheus"
  value       = "http://${aws_eip.monitoring_eip.public_ip}:9090"
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ~/.ssh/id_rsa ubuntu@${aws_eip.monitoring_eip.public_ip}"
}
