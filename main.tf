# Configure the Microsoft Azure Provider
provider "azurerm" {
  # Whilst version is optional, we /strongly recommend/ using it to pin the version of the Provider being used
  version = "=1.34.0"

  subscription_id = "02d0e06b-ed9d-4ca5-bb9f-0a0243a9c9f2"
/*
    client_id       = "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    client_secret   = "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    tenant_id       = "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

*/  
}

# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "agtempgroup" {
    name     = "myResourceGroup"
    location = "eastus"

    tags = {
        environment = "Terraform Demo",
        learntag = "${var.learntag}"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "agtempnetwork" {
    name                = "myVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus"
    resource_group_name = "${azurerm_resource_group.agtempgroup.name}"

    tags = {
        environment = "Terraform Demo",
        learntag = "${var.learntag}"
    }
}

# Create subnet
resource "azurerm_subnet" "agtempsubnet" {
    name                 = "mySubnet"
    resource_group_name  = "${azurerm_resource_group.agtempgroup.name}"
    virtual_network_name = "${azurerm_virtual_network.agtempnetwork.name}"
    address_prefix       = "10.0.1.0/24"
}

# Create public IPs
resource "azurerm_public_ip" "agtemppublicip" {
    name                         = "myPublicIP"
    location                     = "eastus"
    resource_group_name          = "${azurerm_resource_group.agtempgroup.name}"
    allocation_method            = "Dynamic"

    tags = {
        environment = "Terraform Demo",
        learntag = "${var.learntag}"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "agtempnsg" {
    name                = "myNetworkSecurityGroup"
    location            = "eastus"
    resource_group_name = "${azurerm_resource_group.agtempgroup.name}"
    
    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        environment = "Terraform Demo",
        learntag = "${var.learntag}"
    }
}

# Create network interface
resource "azurerm_network_interface" "agtempnic" {
    name                      = "myNIC"
    location                  = "eastus"
    resource_group_name       = "${azurerm_resource_group.agtempgroup.name}"
    network_security_group_id = "${azurerm_network_security_group.agtempnsg.id}"

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = "${azurerm_subnet.agtempsubnet.id}"
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = "${azurerm_public_ip.agtemppublicip.id}"
    }

    tags = {
        environment = "Terraform Demo",
        learntag = "${var.learntag}"
    }
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = "${azurerm_resource_group.agtempgroup.name}"
    }
    
    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = "${azurerm_resource_group.agtempgroup.name}"
    location                    = "eastus"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "Terraform Demo"
        learntag = "${var.learntag}"
    }
}

# Create virtual machine
resource "azurerm_virtual_machine" "agtempvm" {
    name                  = "myVM"
    location              = "eastus"
    resource_group_name   = "${azurerm_resource_group.agtempgroup.name}"
    network_interface_ids = ["${azurerm_network_interface.agtempnic.id}"]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "myvm"
        admin_username = "azureuser"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/azureuser/.ssh/authorized_keys"
            key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC704xhVAxg9Bhq0jIbABWVjKl2DW7apvfFj3UtvActT9a9w1Xt5Fa2jEFuzMXceFtpDjgq5j8E8vsrICu8Wpeqwuo2SR2aAjEjBDfJzOM3kmF9wuWdpacDhVm1luPJiqqM4wLAPufht5vhdlqD8QtW/q84MMHbbkXNjdvgqsIcvDWcCRLQDa1Du3ElF9V+/n182ihIDfQCUtQS0zc9lIcUemZMSLRhxAWA9BZYCu8wnUuLBE/fv8apC0NxOayklSBEj7Pk/HxJnYxTeskqGs5MkzHydObPZSnAtX4Hfe1KlmsAVwt6Sj2bG2AYpt9G0jF7Oq9sYQ6nBTMAxENIsmhB"
        }
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = "${azurerm_storage_account.mystorageaccount.primary_blob_endpoint}"
    }

    tags = {
        environment = "Terraform Demo"
        learntag = "${var.learntag}"
    }
}