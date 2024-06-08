provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_network" "helix" {
  name                   = var.network_name
  auto_create_subnetworks = true
}

resource "google_container_cluster" "helix_gpu_cluster" {
  name       = var.cluster_name
  location   = var.location
  initial_node_count = 1
  min_master_version = "1.28"
  deletion_protection = false

  network    = google_compute_network.helix.self_link

  node_config {
    machine_type = "e2-standard-4"
  }

  monitoring_service = "none"
}

resource "google_container_node_pool" "gpu_node_pool" {
  name       = var.node_pool_name
  cluster    = google_container_cluster.helix_gpu_cluster.name
  location   = google_container_cluster.helix_gpu_cluster.location

  node_config {
    machine_type    = "g2-standard-8"
    guest_accelerator {
      type  = var.gpu_type
      count = 1
      gpu_driver_installation_config {
        gpu_driver_version = var.gpu_driver_version
      }

    }
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/trace.append",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
    ]
  }

  initial_node_count = 1
  autoscaling {
    min_node_count = 0
    max_node_count = 1
  }
}