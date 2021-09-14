/*
terraform {
  required_providers {
    vsphere = {
      #version = "~> 1.23.0"
      version = "1.26.0"
    }
  }
}
*/

data "vsphere_datacenter" "dc" {
  name = var.vcenter_dc_name
}

data "vsphere_datastore" "datastore" {
  name          = var.vcenter_datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "datastore_ext_disk" {
  count = length(var.external_disks)

  name          = var.external_disks[count.index].datastore_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_resource_pool" "pool" {
  count = length(var.vcenter_pool_name != "" ? [1] : [])

  name          = var.vcenter_pool_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  count = length(var.network_configs)

  name          = var.network_configs[count.index].vcenter_network_name
  datacenter_id = data.vsphere_datacenter.dc.id
}
/*
data "vsphere_content_library" "library" {
  name = var.vcenter_library_name
}

data "vsphere_content_library_item" "item" {
  count = length(var.vcenter_library_item_name != "" ? [1] : [])

  name       = var.vcenter_library_item_name
  library_id = data.vsphere_content_library.library.id
  type       = "vm-template"
}
*/
data "vsphere_virtual_machine" "template" {
  count = length(var.vcenter_template_or_vm_name != "" ? [1] : [])

  name          = var.vcenter_template_or_vm_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_vapp_container" "pool" {
  count = length(var.vcenter_vapp_name != "" ? [1] : [])

  name          = var.vcenter_vapp_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_virtual_machine" "vm" {
  name             = var.vcenter_vm_name
  resource_pool_id = var.vcenter_vapp_name != "" ? data.vsphere_vapp_container.pool[0].id : data.vsphere_resource_pool.pool[0].id
  folder           = var.vcenter_vapp_name != "" ? null : var.vcenter_folder
  datastore_id     = data.vsphere_datastore.datastore.id
  enable_disk_uuid = true

  num_cpus = var.num_cpus
  memory   = var.memory_size
  guest_id = var.vm_guest_id
  wait_for_guest_ip_timeout  = var.wait_for_guest_ip_timeout
  wait_for_guest_net_timeout = var.wait_for_guest_net_timeout

  dynamic "network_interface" {
    for_each = [for cfg in var.network_configs : {
      index = cfg.index - 1
    }]

      content  {
        network_id      = data.vsphere_network.network[network_interface.value.index].id
        use_static_mac  = var.network_configs[network_interface.value.index].use_static_mac
        mac_address     = var.network_configs[network_interface.value.index].mac_address       
      }
  }

  lifecycle {
    ignore_changes = [ disk, clone[0].template_uuid ]
  }

  disk {
    label = "disk0"
    size  = var.disk_size
    thin_provisioned = var.disk_thin_provisioned
  }
/*
  dynamic "disk" {
    for_each = [for extd in var.external_disks : {
      index = extd.index - 1
    }]

      content  {
        attach = true
        label = "extdisk-${disk.value.index}"
        unit_number = var.external_disks[disk.value.index].index
        path = var.external_disks[disk.value.index].path

        datastore_id = data.vsphere_datastore.datastore_ext_disk[disk.value.index].id
      }
  }
*/
  clone {
    template_uuid = data.vsphere_virtual_machine.template[0].id

    customize {
      linux_options {
        host_name = var.vm_host
        domain    = var.vm_domain
      }

      dynamic "network_interface" {
        for_each = [for cfg in var.network_configs : {
          index = cfg.index - 1
        }]

          content  {        
            ipv4_address = var.network_configs[network_interface.value.index].vm_ip
            ipv4_netmask = var.network_configs[network_interface.value.index].vm_netmask
          }
      }

      ipv4_gateway = var.vm_gateway
      dns_server_list = var.vm_dns_list
    }
  }

  # The provisioner might not work if "timeout" SSH to VM
  # The "timeout" might caused by ARP caching issue
  provisioner "file" {
    source      = var.provisioner_script
    destination = var.script_entry_dir != "" ? "${var.script_entry_dir}/${var.provisioner_script}" : "/home/${var.admin_user}/${var.provisioner_script}"
  }

  provisioner "remote-exec" {
    inline = [
      "echo '${var.admin_password}' | sudo -S pwd", # Force first time sudo with password
      "if [ '${var.script_entry_dir}' = '' ]; then\n cd /home/${var.admin_user};\n else\n cd ${var.script_entry_dir}; \nfi",
      "chmod +x ${var.provisioner_script}",
      "./${var.provisioner_script} '${var.ssh-pub-key}' '${var.admin_password}'",
    ]
  }

  connection {
    host     = var.ssh_ip_address != "" ? var.ssh_ip_address : self.default_ip_address
    type     = "ssh"
    user     = var.admin_user
    password = var.admin_password

    # Force not to run the script in /tmp, execute program in /tmp might not be allowed for some VM images
    script_path = var.script_entry_dir != "" ? "${var.script_entry_dir}/entry.sh" : "/home/${var.admin_user}/entry.sh"
  }  
}
