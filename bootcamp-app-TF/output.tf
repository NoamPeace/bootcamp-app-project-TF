
# Print public ip
output "public_ip_address" {
  value = data.azurerm_public_ip.ip.ip_address
}

# Print password for the VMs
output "random_password_generated" {
  description = "The password is:"
  value       = random_password.password.*.result
  sensitive   = true

}
