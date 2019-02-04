output "public_ip_address" {
  description = "The actual ip address allocated for the resource."
  value       = "${azurerm_public_ip.cl_jump_pip.ip_address}"
}

output "public_ip_dns_name" {
  description = "fqdn to connect to the first vm provisioned."
  value       = "${azurerm_public_ip.cl_jump_pip.fqdn}"
}

output "rdp_command" {
  value = <<RDPCOMMAND
  ### Use command below to connect via RDP ###
  [
    Command:  mstsc /v:${azurerm_public_ip.cl_jump_pip.fqdn} /admin
    Username: ${var.vm["admin_username"]}
    Password: ${var.vm["admin_password"]}
  ]
RDPCOMMAND
}
