provider "azurerm" {
  # Whilst version is optional, we /strongly recommend/ using it to pin the version of the Provider being used
  version = "=2.5.0"
  features {}
}


resource "azurerm_resource_group" "tb" {
  name     = "tb-resources"
  location = "West Europe"
}

resource "azurerm_virtual_network" "tb" {
  name                = "tb-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.tb.location
  resource_group_name = azurerm_resource_group.tb.name
}

resource "azurerm_subnet" "tb" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.tb.name
  virtual_network_name = azurerm_virtual_network.tb.name
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_public_ip" "tb" {
 count                   = 2
 name                    = "tb-pip-${count.index + 1}"
 location                = azurerm_resource_group.tb.location
 resource_group_name     = azurerm_resource_group.tb.name
 allocation_method       = "Dynamic"
 idle_timeout_in_minutes = 30

  tags = {
    environment = "public-ip"
  }
}


resource "azurerm_network_interface" "tb" {
  count               = 2
  name                = "tb-nic${count.index}"
  location            = azurerm_resource_group.tb.location
  resource_group_name = azurerm_resource_group.tb.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.tb.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = element(azurerm_public_ip.tb.*.id, count.index)
    }
}

//resource "azurerm_managed_disk" "test" {
// count                = 2
// name                 = "datadisk_existing_${count.index}"
// location             = azurerm_resource_group.test.location
// resource_group_name  = azurerm_resource_group.test.name
// storage_account_type = "Standard_LRS"
// create_option        = "Empty"
// disk_size_gb         = "1023"
//}

resource "azurerm_linux_virtual_machine" "tb" {
  count               = 2
  name                = "tbvm${count.index}"
  resource_group_name = azurerm_resource_group.tb.name
  location            = azurerm_resource_group.tb.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  //network_interface_ids = [
  //  azurerm_network_interface.tb.id,
  //]
  network_interface_ids = [element(azurerm_network_interface.tb.*.id, count.index)]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    name              = "myosdisk${count.index}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}

