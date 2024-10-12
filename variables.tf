variable "vsphere_user" {
  description = "vSphere user"
  type        = string
  default = "administrator@vsphere.local"
}

variable "vsphere_password" {
  description = "vSphere password"
  type        = string
  sensitive   = true
  default = "vcenter_pass_here"
}

variable "vsphere_server" {
  description = "vSphere server"
  type        = string
  default = "vcenter_ip_here"
}
