# =================== #
# Deploying VMware VM #
# =================== #

# Connect to VMware vSphere vCenter
provider "vsphere" {
  user           = var.vsphere-user
  password       = var.vsphere-password
  vsphere_server = var.vsphere-vcenter

  # If you have a self-signed cert
  allow_unverified_ssl = var.vsphere-unverified-ssl
}

# Define VMware vSphere
data "vsphere_datacenter" "dc" {
  name = var.vsphere-datacenter
}

data "vsphere_datastore" "datastore" {
  name          = var.vm-datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.vsphere-cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = var.vm-network
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = "/${var.vsphere-datacenter}/vm/${var.vsphere-template-folder}/${var.vm-template-name}"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_tag_category" "category" {
  name = "${var.vsphere_tag_category}"
}

terraform {
  backend "artifactory" {
    username = "jenkins"
    password = "Babyboy2009@"
    url      = "http://192.168.81.175:8081/artifactory"
    repo     = "terraform-state"
    subpath  = ""
  }
}

resource "vsphere_tag" "tag" {
  name        = "${var.vsphere_tag_name}"
  category_id = "${data.vsphere_tag_category.category.id}"
  description = "Managed by Terraform"
}


# Create VMs
resource "vsphere_virtual_machine" "vm" {
  count = var.vm-count

  name             = "${var.vm-name}-${count.index + 1}"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id

  num_cpus = var.vm-cpu
  memory   = var.vm-ram
  guest_id = var.vm-guest-id

  network_interface {
    network_id = data.vsphere_network.network.id
  }

  disk {
    label = "${var.vm-name}-${count.index + 1}-disk"
    size  = 60
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      timeout = 0

      linux_options {
        host_name = "${var.vm-hostname}-${count.index + 1}"
        domain    = var.vm-domain
      }

      network_interface {}
    }
  }
  tags = ["${vsphere_tag.tag.id}"]
}
#===========================#
# VMware vCenter connection #
#===========================#

variable "vsphere-user" {
  type        = string
  description = "VMware vSphere user name"
}

variable "vsphere-password" {
  type        = string
  description = "VMware vSphere password"
}

variable "vsphere-vcenter" {
  type        = string
  description = "VMWare vCenter server FQDN / IP"
}

variable "vsphere-unverified-ssl" {
  type        = string
  description = "Is the VMware vCenter using a self signed certificate (true/false)"
}

variable "vsphere-datacenter" {
  type        = string
  description = "VMWare vSphere datacenter"
}

variable "vsphere-cluster" {
  type        = string
  description = "VMWare vSphere cluster"
  default     = ""
}

variable "vsphere-template-folder" {
  type        = string
  description = "Template folder"
  default = "vm-templates"
}

#================================#
# VMware vSphere virtual machine #
#================================#

variable "vm-count" {
  type        = string
  description = "Number of VM"
  default     =  1
}

variable "vm-name-prefix" {
  type        = string
  description = "Name of VM prefix"
  default     =  "playtftest"
}

variable "vm-datastore" {
  type        = string
  description = "Datastore used for the vSphere virtual machines"
}

variable "vm-network" {
  type        = string
  description = "Network used for the vSphere virtual machines"
}

variable "vm-linked-clone" {
  type        = string
  description = "Use linked clone to create the vSphere virtual machine from the template (true/false). If you would like to use the linked clone feature, your template need to have one and only one snapshot"
  default     = "false"
}

variable "vm-cpu" {
  type        = string
  description = "Number of vCPU for the vSphere virtual machines"
  default     = "2"
}

variable "vm-ram" {
  type        = string
  description = "Amount of RAM for the vSphere virtual machines (example: 2048)"
}

variable "vm-name" {
  type        = string
  description = "The name of the vSphere virtual machines and the hostname of the machine"
}

variable "vm-guest-id" {
  type        = string
  description = "The ID of virtual machines operating system"
}

variable "vm-template-name" {
  type        = string
  description = "The template to clone to create the VM"
}

variable "vm-domain" {
  type        = string
  description = "Linux virtual machine domain name for the machine. This, along with host_name, make up the FQDN of the virtual machine"
  default     = ""
}

variable "vm-hostname" {
  type        = string
  description = "Linux virtual machine host name for the machine."
  default     = ""
}

variable "vsphere_tag_category" {
  type        = string
  description = "vSphere Tag Catagory Details"
}

variable "vsphere_tag_name" {
  type        = string
  description = "vSphere Tag Details"
}









# ======================== #
# VMware VMs configuration #
# ======================== #

vm-count = "${vm_count}"
vm-name = "${vm_name}"
vm-template-name = "${vm_template}"
vm-cpu = "${vm_cpu}"
vm-ram = "${vm_ram}"
vm-guest-id = "${vm_guest_id}"
vm-hostname = "${vm_hostname}"
vsphere_tag_category = "devops"
vsphere_tag_name = "${vm_tag_name}"

# ============================ #
# VMware vSphere configuration #
# ============================ #

# VMware vCenter IP/FQDN
vsphere-vcenter = ""

# VMware vSphere username used to deploy the infrastructure
vsphere-user = ""

# VMware vSphere password used to deploy the infrastructure
vsphere-password = ""

# Skip the verification of the vCenter SSL certificate (true/false)
vsphere-unverified-ssl = "true"

# vSphere datacenter name where the infrastructure will be deployed
vsphere-datacenter = ""

# vSphere cluster name where the infrastructure will be deployed
vsphere-cluster = ""

# vSphere Datastore used to deploy VMs
vm-datastore = ""

# vSphere Network used to deploy VMs
vm-network = ""

# Linux virtual machine domain name
vm-domain = "vsphere.local"
