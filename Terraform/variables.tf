variable "resource_group_location" {
  type        = string
  default     = "eastus"
  description = "Location of resource group."
}

variable "resource_group_name_prefix" {
  type        = string
  default     = "rg"
  description = "Prefix for resource group names."
}

variable "node_count" {
  type        = number
  default     = 3
  description = "The initial quantity of nodes for the node pool."
}


variable "msi_id" {
  type        = string
  default     = null # Set this value if running this example using Managed Identity as the authentication method.
  description = "The Managed Service Identity ID."
}

variable "username" {
  type        = string
  default     = "azureadmin"
  description = "The admin username for the new cluster."
}