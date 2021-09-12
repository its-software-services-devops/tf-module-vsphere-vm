variable "vm_host" {
  description = "VM host"
  default     = ""
}

variable "vm_dns_list" {
  type        = list(string)
  description = "Array of DNS"
  default     = []
}

variable "vm_guest_id" {
  description = "VM Guest ID"
  default     = "centos7_64Guest"
}

variable "vcenter_vm_name" {
  description = "VM name"
  default     = ""
}

#============= common VM properties ==========

variable "admin_user" {    
  default = ""
}

#This is temp password used while provisiong and will be immediately disabled
variable "admin_password" {
  default = ""
}

variable "ssh-pub-key" {
  # Do not store with your code in git, provide on the commandline!
  default = ""
}

variable "ssh_ip_address" {
  default = ""
}

variable "vm_domain" {
  description = "Domain"
  default     = "test.internal"
}

variable "vm_gateway" {
  description = "Gateway IP address"
  default     = ""
}

#============= Vcenter ==============
variable "vcenter_dc_name" {
  description = "Data center name"
  default     = ""
}

variable "vcenter_datastore" {
  description = "Data store name"
  default     = ""
}

variable "vcenter_pool_name" {
  description = "vsphere resource pool name, not need if vApp is used"
  default     = ""
}

variable "vcenter_vapp_name" {
  description = "vApp name"
  default     = ""
}

variable "vcenter_library_name" {
  description = "Content library name"
  default     = "PACKER_VM_TEMPLATE"
}

#This vcenter_library_item_name variable takes higher precendence than vcenter_template_name
variable "vcenter_library_item_name" {
  description = "Library item name"
  default     = ""
}

variable "vcenter_template_or_vm_name" {
  description = "Template name"
  default     = ""
}

variable "vcenter_folder" {
  description = "he path to the folder to put this virtual machine in, not need if vApp is used"
  default     = ""
}

variable "num_cpus" {
  description = "CPU core"
  default     = 1
}

variable "memory_size" {
  description = "Memory in MB"
  default     = 1024
}

variable "disk_size" {
  description = "Disk in GB"
  default     = 100
}

variable "disk_thin_provisioned" {
  type = bool
  default = false
}

variable "provisioner_script" {
  default     = ""
}

variable "script_entry_dir" {
  description = "path to put entry.sh"
  default = ""
}

variable "wait_for_guest_ip_timeout" {
  default     = 0 #Less than 1 to disable
}

variable "wait_for_guest_net_timeout" {
  default     = 5 #Less than 1 to disable
}

# ===================== Network related =================

variable "network_configs" {
  type = list(object({    
    index                = number #User for hint the for_each loop the current index being used, start with 1
    use_static_mac       = bool
    mac_address          = string
    vcenter_network_name = string
    vm_ip                = string
    vm_netmask           = number
  }))

  default = []
}

# ===================== External disk related =================

variable "external_disks" {
  type = list(object({    
    index = number #User for hint the for_each loop the current index being used, start with 1
    path  = string
    datastore_name = string
  }))

  default = []
}

output "virtual_machine_id" {
  value = vsphere_virtual_machine.vm.id
}