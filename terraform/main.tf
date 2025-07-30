terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

resource "google_container_cluster" "primary" {
  name               = var.cluster_name
  location           = var.zone
  initial_node_count = var.initial_node_count
  deletion_protection = false
  
  node_config {
    machine_type = var.machine_type
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
    
    tags = var.node_tags
    
    labels = var.node_labels
  }
  
  ip_allocation_policy {}
  
  resource_labels = var.cluster_labels
}

data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${google_container_cluster.primary.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
}

resource "google_compute_firewall" "wordpress_http" {
  name    = "${var.cluster_name}-http-access"
  network = "default"
  
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  
  source_ranges = ["0.0.0.0/0"]
  description   = "Allow HTTP access to ${var.cluster_name}"
  
  target_tags = var.firewall_target_tags
}

resource "google_compute_firewall" "nodeport_access" {
  name    = "${var.cluster_name}-nodeport-access"
  network = "default"
  
  allow {
    protocol = "tcp"
    ports    = ["30000-32767"]  
  }
  
  source_ranges = ["0.0.0.0/0"]  
  description   = "Allow NodePort access to ${var.cluster_name}"
  
  target_tags = var.node_tags
}