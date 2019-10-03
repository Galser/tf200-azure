# Configure the Microsoft Azure Provider
provider "azurerm" {
  # Whilst version is optional, we /strongly recommend/ using it to pin the version of the Provider being used
  version = "=1.34.0"

  subscription_id = "02d0e06b-ed9d-4ca5-bb9f-0a0243a9c9f2"
}
  module "linuxservers" {
    source                        = "Azure/compute/azurerm"
    resource_group_name           = "aztemp-advancedvms"
    location                      = "westus2"
    vm_hostname                   = "agtemplinuxvm"
    nb_public_ip                  = "0"
    remote_port                   = "22"
    nb_instances                  = "2"
    vm_os_publisher               = "Canonical"
    vm_os_offer                   = "UbuntuServer"
    vm_os_sku                     = "14.04.2-LTS"
    vnet_subnet_id                = "${module.network.vnet_subnets[0]}"
    boot_diagnostics              = "true"
    delete_os_disk_on_termination = "true"
    data_disk                     = "true"
    data_disk_size_gb             = "64"
    data_sa_type                  = "Premium_LRS"

    tags = {
      environment = "dev"
      costcenter  = "it"
    }

    #enable_accelerated_networking = "true"
  }

  module "network" {
    source              = "Azure/network/azurerm"
    version             = "~> 1.1.1"
    location            = "westus2"
    allow_rdp_traffic   = "true"
    allow_ssh_traffic   = "true"
    resource_group_name = "aztemp-advancedvms"
  }

  output "linux_vm_private_ips" {
    value = "${module.linuxservers.network_interface_private_ip}"
  }
  output "linux_vm_public_name"{
    value = "${module.linuxservers.public_ip_dns_name}"
  }