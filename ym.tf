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
