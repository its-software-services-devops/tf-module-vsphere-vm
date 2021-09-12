variable "vcenter_username" {
  description = "Username to vcenter"
  default     = ""
}

variable "vcenter_password" {
  description = "Password to vcenter"
  default     = ""
}

variable "vcenter_host" {
  description = "vcenter host"
  default     = ""
}

variable "branch" {
  description = "State files folder"
  default     = "develop"
}

variable "admin_password" {
  description = "Admin password SSH to VM"
  default = ""
}

variable "vm_public_key" {
  description = "VM public key"
  default = ""
}
