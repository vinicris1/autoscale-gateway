output "vm_ips" {
  description = "ip for each vm by name"
  value       = { for k, v in var.vms : k => v.ip }
}
