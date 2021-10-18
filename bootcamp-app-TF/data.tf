
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

