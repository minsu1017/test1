resource "azurerm_resource_group" "rg" {
  name     = "user28-rg"
  location = "koreasouth"
}

variable "application_port" {
   description = "The port that you want to expose to the external load balancer"
   default     = 80
}
resource "azurerm_network_security_group" "secGroup" {
    name = "user28-secGroup"
    location = "koreasouth"
    resource_group_name ="${azurerm_resource_group.rg.name}"

    security_rule {
        name ="SSH"
        priority = "1001"
        direction = "Inbound"
        access = "Allow"
        protocol = "Tcp"
        source_port_range = "*"
        destination_port_range = "22"
        source_address_prefix = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name = "HTTP"
        priority = "2001"
        direction = "Inbound"
        access = "Allow"
        protocol = "Tcp"
        source_port_range = "*"
        destination_port_range = "80"
        source_address_prefix = "*"
        destination_address_prefix = "*"
    }
}

resource "azurerm_network_security_group" "secGroup2" {
    name = "user28-secGroup2"
    location = "koreasouth"
    resource_group_name ="${azurerm_resource_group.rg.name}"

    security_rule {
        name ="SSH"
        priority = "1001"
        direction = "Inbound"
        access = "Allow"
        protocol = "Tcp"
        source_port_range = "*"
        destination_port_range = "22"
        source_address_prefix = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name = "HTTP"
        priority = "2001"
        direction = "Inbound"
        access = "Allow"
        protocol = "Tcp"
        source_port_range = "*"
        destination_port_range = "80"
        source_address_prefix = "*"
        destination_address_prefix = "*"
    }
    security_rule {
        name = "DB"
        priority = "3001"
        direction = "Inbound"
        access = "Allow"
        protocol = "Tcp"
        source_port_range = "*"
        destination_port_range = "3306"
        source_address_prefix = "*"
        destination_address_prefix = "*"
    }    
}

resource "azurerm_virtual_network" "vnetwork" {
    name = "user28-vnet"
    address_space = ["28.0.0.0/16"]
    location = "koreasouth"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    
}

resource "azurerm_subnet" "mysubnet" {
    name = "user28-mysubnet"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    virtual_network_name = "${azurerm_virtual_network.vnetwork.name}"
    network_security_group_id = "${azurerm_network_security_group.secGroup.id}"
    address_prefix = "28.0.1.0/24"
}

resource "azurerm_subnet" "mysubnet2" {
    name = "user28-mysubnet2"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    virtual_network_name = "${azurerm_virtual_network.vnetwork.name}"
    network_security_group_id = "${azurerm_network_security_group.secGroup2.id}"
    address_prefix = "28.0.2.0/24"
}

resource "azurerm_public_ip" "publicip" {
 name                         = "user28-publicip"
 location                     = "koreasouth"
 resource_group_name          = "${azurerm_resource_group.rg.name}"
 allocation_method            = "Dynamic"
}

resource "azurerm_network_interface" "nic" {
  name                = "user28-nic"
  location            = "koreasouth"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  network_security_group_id = "${azurerm_network_security_group.secGroup.id}"  

  ip_configuration {
    name                                    = "user28-ip1"
    subnet_id                               = "${azurerm_subnet.mysubnet.id}"
    private_ip_address_allocation           = "Dynamic"
    public_ip_address_id = "${azurerm_public_ip.publicip.id}"	
  }
}

resource "azurerm_availability_set" "avset" {
  name                         = "avset-user28"
  location                     = "koreasouth"
  resource_group_name          = "${azurerm_resource_group.rg.name}"
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
}

resource "azurerm_virtual_machine" "vm" {
  name                  = "user28-vm"
  location              = "koreasouth"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  availability_set_id   = "${azurerm_availability_set.avset.id}"
  network_interface_ids = ["${azurerm_network_interface.nic.id}"]
  vm_size = "Standard_D1_v2"

  storage_os_disk {
        name = "user28-osdisk"
        caching = "ReadWrite"
        create_option = "FromImage"
        managed_disk_type = "Standard_LRS"
  }
  storage_image_reference {
        publisher = "RedHat"
        offer     = "RHEL"
        sku       = "7.4"
        version   = "latest"
    }  

  os_profile {
        computer_name = "user28-vm"
        admin_username = "azureuser28"
        admin_password= "dlatl!00"		
  }
  os_profile_linux_config {
        disable_password_authentication = false											 
  }
}
