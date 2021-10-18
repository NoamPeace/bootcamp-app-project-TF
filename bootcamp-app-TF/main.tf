# Configure terraform to store tfstate in azure blob storage
terraform {
  backend "azurerm" {
    storage_account_name = "tfstate15063"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
    access_key           = "AWXtBbGDbraudtICkKWcFv66o7NqeEDD6qnDztNrwUWRFOPBBkPWA06CK/QJ6e0SUm/s4zX5I0Z3F2MKguNOXw=="
  }
}


# Generate a random password
resource "random_string" "password" {
  length           = 16
  special          = true
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  override_special = "_%@"
}



# Create Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Create a virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "bootcamp_Week5-Vnet"
  address_space       = [var.vnet-cidr]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}



# Create 2 subnet :Public and Private
resource "azurerm_subnet" "subnet" {
  name                 = var.subnet_name[count.index]
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_prefix[count.index]]
  count                = 2
}

# Create a public IP
resource "azurerm_public_ip" "publicip" {
  name                = "bootcamp_Week5-PublicIP"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"

}




#Create a Load Balancer
resource "azurerm_lb" "publicLB" {
  name                = "bootcamp_Week5-LoadBalancer"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  frontend_ip_configuration {
    name                 = "bootcamp_Week5-LB-PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.publicip.id
  }
}

#Create a backend address pool for the load balancer
resource "azurerm_lb_backend_address_pool" "backend_address_pool_public" {
  loadbalancer_id = azurerm_lb.publicLB.id
  name            = "bootcamp_Week5-Backend_Address_Pool"

}


#Associate network interface1 to the load balancer backend address pool
# resource "azurerm_network_interface_backend_address_pool_association" "nic_back_association" {
#   network_interface_id    = azurerm_network_interface.nic.id
#   ip_configuration_name   = azurerm_network_interface.nic.ip_configuration[0].name
#   backend_address_pool_id = azurerm_lb_backend_address_pool.backend_address_pool_public.id
# }
#Associate network interface2 to the load balancer backend address pool
# resource "azurerm_network_interface_backend_address_pool_association" "nic2_back_association" {
#   network_interface_id    = azurerm_network_interface.nic2.id
#   ip_configuration_name   = azurerm_network_interface.nic2.ip_configuration[0].name
#   backend_address_pool_id = azurerm_lb_backend_address_pool.backend_address_pool_public.id
# }
#Associate network interface3 to the load balancer backend address pool
# resource "azurerm_network_interface_backend_address_pool_association" "nic3_back_association" {
#   network_interface_id    = azurerm_network_interface.nic3.id
#   ip_configuration_name   = azurerm_network_interface.nic3.ip_configuration[0].name
#   backend_address_pool_id = azurerm_lb_backend_address_pool.backend_address_pool_public.id
# }





#Create load balancer probe for port 8080
resource "azurerm_lb_probe" "lb_probe" {
  name                = "bootcamp_Week5-LB_tcpProbe"
  resource_group_name = azurerm_resource_group.rg.name
  loadbalancer_id     = azurerm_lb.publicLB.id
  protocol            = "HTTP"
  port                = 8080
  interval_in_seconds = 5
  number_of_probes    = 2
  request_path        = "/"

}




#Create load balancer rule for port 8080
resource "azurerm_lb_rule" "bootcamp_Week5-LB_rule8080" {
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.publicLB.id
  name                           = "LBRule"
  protocol                       = "Tcp"
  frontend_port                  = 8080
  backend_port                   = 8080
  frontend_ip_configuration_name = azurerm_lb.publicLB.frontend_ip_configuration[0].name
  probe_id                       = azurerm_lb_probe.lb_probe.id
  backend_address_pool_id        = azurerm_lb_backend_address_pool.backend_address_pool_public.id
}





#Create public availability set
resource "azurerm_availability_set" "availability_set1" {
  name                = "bootcamp_Week5-AVset"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

}




# Create Network Security Group and rules for the app
resource "azurerm_network_security_group" "nsg" {
  name                = "bootcamp_Week5-APP-NSG"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name


  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "22"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Port_8080"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}




#Associate subnet to subnet_network_security_group
resource "azurerm_subnet_network_security_group_association" "public" {
  subnet_id                 = azurerm_subnet.subnet[0].id
  network_security_group_id = azurerm_network_security_group.nsg.id
}



#Associate network interface1 to public subnet_network_security_group
# resource "azurerm_network_interface_security_group_association" "nsg_nic" {
#   network_interface_id      = azurerm_network_interface.nic.id
#   network_security_group_id = azurerm_network_security_group.nsg.id
# }


#Associate network interface2 to public subnet_network_security_group
# resource "azurerm_network_interface_security_group_association" "nsg_nic2" {
#   network_interface_id      = azurerm_network_interface.nic2.id
#   network_security_group_id = azurerm_network_security_group.nsg.id
# }

#Associate network interface3 to public subnet_network_security_group
# resource "azurerm_network_interface_security_group_association" "nsg_nic3" {
#   network_interface_id      = azurerm_network_interface.nic3.id
#   network_security_group_id = azurerm_network_security_group.nsg.id
# }


#Associate db network interface to db subnet_network_security_group
# resource "azurerm_network_interface_security_group_association" "dbnsg" {
#   network_interface_id      = azurerm_network_interface.dbnic.id
#   network_security_group_id = azurerm_network_security_group.dbnsg.id
# }



resource "azurerm_virtual_machine_scale_set" "vmss" {
  name                = "vmscaleset"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  upgrade_policy_mode = "Manual"

  sku {
    name     = var.public_vm_size
    tier     = "Standard"
    capacity = 2
  }

  storage_profile_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name_prefix = "appVM"
    admin_username       = var.ubuntu_username
    admin_password       = random_string.password.result
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  network_profile {
    name    = "terraformnetworkprofile"
    primary = true

    ip_configuration {
      name                                   = "IPConfiguration"
      subnet_id                              = azurerm_subnet.subnet[0].id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.backend_address_pool_public.id]
      primary                                = true
    }
  }
}






#Create Postgresql Server
resource "azurerm_postgresql_server" "postgres" {
  name                = "bootcamp-week5-db"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku_name = "B_Gen5_2"

  storage_mb                   = 5120
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled            = true

  administrator_login          = var.pg_admin
  administrator_login_password = var.pg_admin_password
  version                      = "11"
  ssl_enforcement_enabled      = false
}




#Create Postgres firewall rule
resource "azurerm_postgresql_firewall_rule" "postgres_firewall" {
  name                = "bootcamp-week5-db-firewall"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_postgresql_server.postgres.name
  start_ip_address    = data.azurerm_public_ip.ip.ip_address
  end_ip_address      = data.azurerm_public_ip.ip.ip_address
}
