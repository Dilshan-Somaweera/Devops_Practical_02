variable "project_id" {}

variable "region" {
  default = "asia-south1"
}

variable "zone" {
  default = "asia-south1-a"
}

variable "cluster_name" {
  default = "task01"
}

variable "initial_node_count" {
  default = 1
}

variable "machine_type" {
  default = "e2-small"
}

variable "cluster_labels" {
  type = map(string)
  default = {
    environment = "dev"
    project     = "task01"
    managed-by  = "terraform"
  }
}

variable "node_labels" {
  type = map(string)
  default = {
    environment = "dev"
    project     = "task01"
    node-pool   = "primary"
  }
}

variable "node_tags" {
  type = list(string)
  default = ["task01-cluster", "gke-node"]
}

variable "firewall_target_tags" {
  type = list(string)
  default = ["task01-cluster"]
}