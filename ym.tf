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

resource "vsphere_tag" "tag" {
  name        = "${var.vsphere_tag_name}"
  category_id = "${data.vsphere_tag_category.category.id}"
  description = "Managed by Terraform"
}

# Create VMs
resource "vsphere_virtual_machine" "vm" {
  count            = var.vm-count
  name             = var.staticvmname != null ? var.staticvmname : "${var.vm-name}-${count.index + 1}"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  num_cpus         = var.vm-cpu
  memory           = var.vm-ram
  guest_id         = data.vsphere_virtual_machine.template.guest_id
  tags             = ["${vsphere_tag.tag.id}"]
  scsi_type        = var.scsi_type != "" ? var.scsi_type : data.vsphere_virtual_machine.template.scsi_type
  firmware         = var.firmware == null ? data.vsphere_virtual_machine.template.firmware : var.firmware

  network_interface {
    network_id = data.vsphere_network.network.id
  }

  disk {
    label = var.staticvmname != null ? "${var.staticvmname}-disk" : "${var.vm-name}-${count.index + 1}-disk"
    size  = var.disk_size != null ? var.disk_size : data.vsphere_virtual_machine.template.disks.0.size
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    timeout       = var.timeout

    customize {
      dynamic "linux_options" {
        for_each = var.is_windows_image ? [] : [1]
        content {
          host_name = var.staticvmname != null ? var.staticvmname : "${var.vm-hostname}-${count.index + 1}"
          domain    = var.vm-domain
        }
      }

      dynamic "windows_options" {
        for_each = var.is_windows_image ? [1] : []
        content {
          computer_name        = var.staticvmname != null ? var.staticvmname : "${var.vm-name}-${count.index + 1}"
          auto_logon           = var.auto_logon
          admin_password       = var.local_adminpass
        }
      }

      network_interface {}
    }
  }
}


output "DC_ID" {
  description = "id of vSphere Datacenter"
  value       = data.vsphere_datacenter.dc.id
}

output "VM" {
  description = "VM Names"
  value       = vsphere_virtual_machine.vm.*.name
}

output "ip" {
  description = "default ip address of the deployed VM"
  value       = vsphere_virtual_machine.vm.*.default_ip_address
}

output "guest-ip" {
  description = "all the registered ip address of the VM"
  value       = vsphere_virtual_machine.vm.*.guest_ip_addresses
}

output "uuid" {
  description = "UUID of the VM in vSphere"
  value       = vsphere_virtual_machine.vm.*.uuid
}

output "disk" {
  description = "Disks of the deployed VM"
  value       = vsphere_virtual_machine.vm.*.disk
}


#===========================#
# VMware vCenter connection #
#===========================#
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
  default     = "vm-templates"
}

#================================#
# VMware vSphere virtual machine #
#================================#

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

variable "vm-template-name" {
  type        = string
  description = "The template to clone to create the VM"
}

variable "vsphere_tag_category" {
  type        = string
  description = "vSphere Tag Catagory Details"
}

variable "staticvmname" {
  description = "Static name of the virtual machin."
  default     = null
}

variable "scsi_type" {
  description = "scsi_controller type, acceptable values lsilogic,pvscsi."
  type        = string
  default     = ""
}

variable "firmware" {
  description = "The firmware interface to use on the virtual machine. Can be one of bios or EFI. Default: Inherited from cloned template"
  default     = null
}

variable "disk_size" {
  description = "disk size(GB) to override template disk size."
  type        = string
  default     = null
}

variable "timeout" {
  description = "The timeout, in minutes, to wait for the virtual machine clone to complete."
  type        = number
  default     = 30
}

variable "is_windows_image" {
  description = "Boolean flag to notify when the custom image is windows based."
  type        = bool
  default     = false
}

variable "vm-count" {
  type        = string
  description = "Number of VM"
  default     = 1
}

variable "vm-name" {
  type        = string
  description = "The name of the vSphere virtual machines and the hostname of the machine"
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

variable "vm-hostname" {
  type        = string
  description = "Linux virtual machine host name for the machine."
  default     = ""
}

variable "vsphere_tag_name" {
  type        = string
  description = "vSphere Tag Details"
}

variable "vm-domain" {
  type        = string
  description = "Linux virtual machine domain name for the machine. This, along with host_name, make up the FQDN of the virtual machine"
  default     = ""
}

variable "auto_logon" {
  description = " Specifies whether or not the VM automatically logs on as Administrator. Default: false."
  type        = bool
  default     = null
}

variable "local_adminpass" {
  description = "The administrator password for this virtual machine.(Required) when using join_windomain option."
  default     = null
}





terraform {
  required_version = ">= 0.13.3"
}




provider "vsphere" {
  user                 = ""
  password             = ""
  vsphere_server       = ""
  allow_unverified_ssl = "true"
}

module "rhel" {
  source               = "../vmware-base-host"
  vm-template-name     = "RHEL7-Template"
  vsphere_tag_category = "devops"
  vsphere-datacenter   = "MyLab"
  vsphere-cluster      = "LabCluster"
  vm-datastore         = "SharedVM"
  vm-network           = "VM Network"
  vm-count             = "1"
  vm-name              = "rhel-test"
  vm-cpu               = "2"
  vm-ram               = "4096"
  vm-hostname          = "rhel-test"
  vsphere_tag_name     = "rhel-test"
  staticvmname         = "rhel-test"
  vm-domain            = "vsphere.local"
}
  
  

  
provider "vsphere" {
  user                 = ""
  password             = ""
  vsphere_server       = ""
  allow_unverified_ssl = "true"
}

module "rhel" {
  source               = "../vmware-base-host"
  vm-template-name     = "win2019-template"
  vsphere_tag_category = "devops"
  vsphere-datacenter   = "MyLab"
  vsphere-cluster      = "LabCluster"
  vm-datastore         = "SharedVM"
  vm-network           = "VM Network"
  vm-count             = "1"
  vm-name              = "win-test"
  vm-cpu               = "2"
  vm-ram               = "6144"
  vm-hostname          = "win-test"
  vsphere_tag_name     = "win-test"
  staticvmname         = "win-test"
  scsi_type            = "lsilogic-sas"
  is_windows_image     = true
  firmware             = "bios"
  auto_logon           = "true"
  local_adminpass      = ""
}
  
 ---

# Install xfs package
- name: Install xfs package
  yum:
    name: "{{ item }}"
    state: present
  with_items: "{{ pkgs }}"

# Create directory if it doesn't exist
- name: Create mount directory if it doesn't exist
  file:
    path: "{{ mount_path }}"
    state: directory
    owner: root
    group: root
    mode: 0755

# Gather facts about mounted devices
- name: Create list of mounted devices
  set_fact:
    mounted_devices: "{{ ansible_mounts|json_query('[].device') }}"

- debug:
    msg: "{{ mounted_devices }}"

# Create filesystem if not in the mounted device list
- name: Create File System
  filesystem:
    fstype: "{{ fstype }}"
    dev: "{{ mount_src }}"
  when: mount_src not in mounted_devices

# Mount filesystem to path
- name: Mount File System
  mount:
    path: "{{ mount_path }}"
    src: "{{ mount_src }}"
    fstype: "{{ fstype }}"
    state: mounted
  when: mount_src not in mounted_devices

# Get UUID of new device
- name: "Get UUID of new"
  command: "lsblk -no UUID {{ mount_src }}"
  register: uuid_output

- debug:
    msg: "{{ uuid_output }}"

# Mount on system reboot
- name: Add mount details to /etc/fstab
  lineinfile: 
    backup: yes
    state: present
    path: "{{ fstab_path }}"
    line: 'UUID={{ uuid_output.stdout }}  {{ mount_path }}  {{ fstype }}  defaults,nofail  0  2'


pkgs:
  - xfsprogs

fstab_path: /etc/fstab
