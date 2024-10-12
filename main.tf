terraform {
  required_version = "= 1.5.6"  # Specifies the exact version of Terraform that must be used for this configuration

  required_providers {
    vsphere = {
      source  = "registry.terraform.io/hashicorp/vsphere"  # Source of the vSphere provider
      version = "2.3.0"  # Specifies the desired version of the vSphere provider
    }
  }
}

# Provider configuration for vSphere
provider "vsphere" {
  user           = var.vsphere_user         # vSphere username from variable
  password       = var.vsphere_password     # vSphere password from variable
  vsphere_server = var.vsphere_server       # vSphere server address from variable

  # Allow self-signed SSL certificates
  allow_unverified_ssl = true
  api_timeout          = 60                   # Timeout for API requests
}

# Data Sources

# Retrieve data about the vSphere datacenter
data "vsphere_datacenter" "datacenter" {
  name = "DC"  # Name of the datacenter
}

# Retrieve data about the vSphere datastore
data "vsphere_datastore" "datastore" {
  name          = "datastore1 (1)"  # Name of the datastore
  datacenter_id = data.vsphere_datacenter.datacenter.id  # Link to the datacenter ID
}

# Retrieve data about the vSphere compute cluster
data "vsphere_compute_cluster" "cluster" {
  name          = "Cluster"  # Name of the compute cluster
  datacenter_id = data.vsphere_datacenter.datacenter.id  # Link to the datacenter ID
}

# Retrieve data about the vSphere network
data "vsphere_network" "network" {
  name          = "VM Network"  # Name of the network
  datacenter_id = data.vsphere_datacenter.datacenter.id  # Link to the datacenter ID
}

# Retrieve data about the virtual machine template to be cloned
data "vsphere_virtual_machine" "template" {
  name          = "ubuntu-focal-20.04-cloudimg"  # Name of the VM template
  datacenter_id = data.vsphere_datacenter.datacenter.id  # Link to the datacenter ID
}

# Resource: Virtual Machine

# Create a new virtual machine
resource "vsphere_virtual_machine" "vm" {
  name             = "tf-vm01"  # Name of the virtual machine
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id  # Resource pool for the VM
  datastore_id     = data.vsphere_datastore.datastore.id  # Datastore for the VM

  # CD-ROM configuration
  cdrom {
    client_device = true  # Attach the CD-ROM to the client device
  }

  num_cpus = 2  # Number of virtual CPUs
  memory   = 4096  # Amount of memory in MB
  guest_id = data.vsphere_virtual_machine.template.guest_id  # Guest OS ID from the template

  # Network interface configuration
  network_interface {
    network_id   = data.vsphere_network.network.id  # Network to connect the VM
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]  # Adapter type from template
  }

  # Disk configuration
  disk {
    label            = "disk1"  # Label for the disk
    size             = 10        # Size of the disk in GB
    
    # unit_number      = 1        # (Optional) Specify the unit number of the disk
    # controller_type  = "ide"    # (Optional) Specify the controller type (IDE/SCSI)
  }
  
  # Cloning configuration from the template
  clone {
    template_uuid = data.vsphere_virtual_machine.template.id  # UUID of the template to clone from
    customize {
      linux_options {
        host_name = "tf-vm01"  # Hostname for the new VM
        domain    = "tf.fc.local"  # Domain name for the new VM
      }

      # Network configuration for the cloned VM
      network_interface {
        ipv4_address = "192.168.1.110"  # Static IPv4 address for the VM
        ipv4_netmask = 24                # Subnet mask for the VM
      }
      ipv4_gateway = "192.168.1.1"  # Gateway for the VM
    }    
  }
}

# Outputs

# Output the ID of the created virtual machine
output "vm_id" {
  value = vsphere_virtual_machine.vm.id  # ID of the VM resource
}

# Output the default IP address of the created virtual machine
output "vm_ip" {
  value = vsphere_virtual_machine.vm.default_ip_address  # Default IP address of the VM
}
