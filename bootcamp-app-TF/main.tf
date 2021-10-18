# Generate a random password
resource "random_password" "password" {
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


# Delay before network interfaces creation for 30 seconds
resource "null_resource" "delay_nics" {
  provisioner "local-exec" {
    command = "sleep 30"
  }

  triggers = {
    "before" = "${azurerm_network_interface.nic.id}"
  }
}



# Create a network interface for first VM
resource "azurerm_network_interface" "nic" {
  name                = "bootcamp_Week5-NIC1"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "bootcamp_Week5-NIC1_Conf"
    subnet_id                     = azurerm_subnet.subnet[0].id
    private_ip_address_allocation = "dynamic"
  }
}




# Create a network interface for second VM
resource "azurerm_network_interface" "nic2" {
  name                = "bootcamp_Week5-NIC2"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "bootcamp_Week5-NIC2_Conf"
    subnet_id                     = azurerm_subnet.subnet[0].id
    private_ip_address_allocation = "dynamic"
  }
}


# Create a network interface for third VM
resource "azurerm_network_interface" "nic3" {
  name                = "bootcamp_Week5-NIC3"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "bootcamp_Week5-NIC3_Conf"
    subnet_id                     = azurerm_subnet.subnet[0].id
    private_ip_address_allocation = "dynamic"
  }
}




# Create a network interface for the DB VM
resource "azurerm_network_interface" "dbnic" {
  name                = "bootcamp_Week5-NIC-DB"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "bootcamp_Week5-NIC-DB_Conf"
    subnet_id                     = azurerm_subnet.subnet[1].id
    private_ip_address_allocation = "dynamic"
  }
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
resource "azurerm_network_interface_backend_address_pool_association" "nic_back_association" {
  network_interface_id    = azurerm_network_interface.nic.id
  ip_configuration_name   = azurerm_network_interface.nic.ip_configuration[0].name
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_address_pool_public.id
}
#Associate network interface2 to the load balancer backend address pool
resource "azurerm_network_interface_backend_address_pool_association" "nic2_back_association" {
  network_interface_id    = azurerm_network_interface.nic2.id
  ip_configuration_name   = azurerm_network_interface.nic2.ip_configuration[0].name
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_address_pool_public.id
}
#Associate network interface3 to the load balancer backend address pool
resource "azurerm_network_interface_backend_address_pool_association" "nic3_back_association" {
  network_interface_id    = azurerm_network_interface.nic3.id
  ip_configuration_name   = azurerm_network_interface.nic3.ip_configuration[0].name
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_address_pool_public.id
}





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
    source_address_prefix      = "2.53.130.34"
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


# Create Network Security Group and rules for the DB
resource "azurerm_network_security_group" "dbnsg" {
  name                = "bootcamp_Week5-DB-NSG"
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

}



#Associate subnet to subnet_network_security_group
resource "azurerm_subnet_network_security_group_association" "public" {
  subnet_id                 = azurerm_subnet.subnet[0].id
  network_security_group_id = azurerm_network_security_group.nsg.id
}


#Associate private subnet to subnet_DB network_security_group
resource "azurerm_subnet_network_security_group_association" "private" {
  subnet_id                 = azurerm_subnet.subnet[1].id
  network_security_group_id = azurerm_network_security_group.dbnsg.id
}




#Associate network interface1 to public subnet_network_security_group
resource "azurerm_network_interface_security_group_association" "nsg_nic" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}


#Associate network interface2 to public subnet_network_security_group
resource "azurerm_network_interface_security_group_association" "nsg_nic2" {
  network_interface_id      = azurerm_network_interface.nic2.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

#Associate network interface3 to public subnet_network_security_group
resource "azurerm_network_interface_security_group_association" "nsg_nic3" {
  network_interface_id      = azurerm_network_interface.nic3.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}


#Associate db network interface to db subnet_network_security_group
resource "azurerm_network_interface_security_group_association" "dbnsg" {
  network_interface_id      = azurerm_network_interface.dbnic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}



# Create a Linux virtual machine 1
resource "azurerm_virtual_machine" "vm" {
  name                  = "bootcamp_Week5-AppVM1"
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg.name
  availability_set_id   = azurerm_availability_set.availability_set1.id
  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size               = var.public_vm_size

  storage_os_disk {
    name              = "bootcamp_Week5-AppVM1_OsDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"

  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "bootcampWeek5VM1"
    admin_username = var.ubuntu_username
    admin_password = random_password.password.result
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

# resource "azurerm_virtual_machine_extension" "app1_terraform" {
#   name                 = "VM1_customscript"
#   virtual_machine_id   = azurerm_virtual_machine.vm.id
#   publisher            = "Microsoft.Azure.Extensions"
#   type                 = "CustomScript"
#   type_handler_version = "2.0"
#
#   settings = <<SETTINGS
#    {
#        "fileUris": ["https://raw.githubusercontent.com/NoamPeace/bootcamp-app-project-TF/main/vm-scripts/appvm-script.sh"],
#        "commandToExecute": "appvm-script.sh ${join(" ", [data.azurerm_public_ip.ip.ip_address, var.okta_url, var.okta_clientid, var.okta_secret, "replace_with_data_domain_of_db", var.pg_admin, var.pg_admin_password, var.ubuntu_username])}",
#    }
# SETTINGS
# }


# Create a Linux virtual machine 2
resource "azurerm_virtual_machine" "vm2" {
  name                  = "bootcamp_Week5-AppVM2"
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic2.id]
  vm_size               = var.public_vm_size
  availability_set_id   = azurerm_availability_set.availability_set1.id

  storage_os_disk {
    name              = "bootcamp_Week5-AppVM2_OsDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"

  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "bootcampWeek5VM2"
    admin_username = var.ubuntu_username
    admin_password = random_password.password.result
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

# resource "azurerm_virtual_machine_extension" "app2_terraform" {
#   name                 = "VM2_customscript"
#   virtual_machine_id   = azurerm_virtual_machine.vm2.id
#   publisher            = "Microsoft.Azure.Extensions"
#   type                 = "CustomScript"
#   type_handler_version = "2.0"
#
#   settings = <<SETTINGS
#     {
#         "fileUris": ["https://raw.githubusercontent.com/NoamPeace/bootcamp-app-project-TF/main/vm-scripts/appvm-script.sh"],
#         "commandToExecute": "bash appvm-script.sh ${data.azurerm_public_ip.ip.ip_address} ${var.okta_url} ${var.okta_clientid} ${var.okta_secret} replace_with_data_domain_of_db ${var.pg_admin} ${var.pg_admin_password} ${var.ubuntu_username}"
#     }
# SETTINGS
# }


# Create a Linux virtual machine 3
resource "azurerm_virtual_machine" "vm3" {
  name                  = "bootcamp_Week5-AppVM3"
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic3.id]
  vm_size               = var.public_vm_size
  availability_set_id   = azurerm_availability_set.availability_set1.id

  storage_os_disk {
    name              = "bootcamp_Week5-AppVM3_OsDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"

  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "bootcampWeek5VM3"
    admin_username = var.ubuntu_username
    admin_password = random_password.password.result
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

# resource "azurerm_virtual_machine_extension" "app3_terraform" {
#   name                 = "VM3_customscript"
#   virtual_machine_id   = azurerm_virtual_machine.vm3.id
#   publisher            = "Microsoft.Azure.Extensions"
#   type                 = "CustomScript"
#   type_handler_version = "2.0"
#
#   settings = <<SETTINGS
#     {
#         "fileUris": ["https://raw.githubusercontent.com/NoamPeace/bootcamp-app-project-TF/main/vm-scripts/appvm-script.sh"],
#         "commandToExecute": "bash appvm-script.sh ${data.azurerm_public_ip.ip.ip_address} ${var.okta_url} ${var.okta_clientid} ${var.okta_secret} replace_with_data_domain_of_db ${var.pg_admin} ${var.pg_admin_password} ${var.ubuntu_username}"
#     }
# SETTINGS
# }

# Create a Linux virtual machine for db
resource "azurerm_virtual_machine" "dbvm" {
  name                = "bootcamp_Week5-dbVM"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  #  availability_set_id   = azurerm_availability_set.availability_set1.id
  network_interface_ids = [azurerm_network_interface.dbnic.id]
  vm_size               = var.public_vm_size

  storage_os_disk {
    name              = "bootcamp_Week5-dbVM1_OsDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"

  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "bootcampWeek5VM4-DB"
    admin_username = var.ubuntu_username
    admin_password = random_password.password.result
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}



#Get data from vnet
data "azurerm_virtual_network" "data_vnet" {
  name                = azurerm_virtual_network.vnet.name
  resource_group_name = var.resource_group_name
}
#Get data from load balancer
data "azurerm_lb" "data_lb" {
  name                = azurerm_lb.publicLB.name
  resource_group_name = var.resource_group_name
}
#Get data from backend address pool
data "azurerm_lb_backend_address_pool" "data_pool" {
  name            = azurerm_lb_backend_address_pool.backend_address_pool_public.name
  loadbalancer_id = data.azurerm_lb.data_lb.id
}

