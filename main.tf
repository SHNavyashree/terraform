provider "azurerm" {
  features {}
subscription_id = "fb99e83f-61c2-4969-a2b1-eccab005dbe6"
  client_id       = "efded17c-1368-4a74-8f71-21b5c00b1614"
  client_secret   = "z3O8Q~8o3DiTMgojouO~LfGgzkAepdzxjotEMa1y"
  tenant_id       = "25685456-cb13-4603-8519-85d676907ffc"

}

resource "azurerm_resource_group" "rg" {
  name     = "d-rg"
  location = "East US"
  }

resource "azurerm_virtual_network" "vnet" {
  name                = "devops-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "devops-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
   virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "nic" {
  name                = "devops-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
     private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public.id
  }
}

resource "azurerm_public_ip" "public" {
  name                = "example-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"  # <-- Required for Standard SKU
  sku                 = "Standard"
  
  tags = {
    environment = "Terraform"
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "devops-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"
   network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
     }
source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}
