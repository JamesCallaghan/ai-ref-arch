variable "project_id" {
  description = "The ID of the Google Cloud project"
  type        = string
}

variable "network_name" {
  description = "The name of the network"
  default     = "helix"
}

variable "cluster_name" {
  description = "The name of the Kubernetes cluster"
  default     = "helix-gpu-cluster"
}

variable "node_pool_name" {
  description = "The name of the node pool"
  default     = "gpu-node-pool"
}

variable "region" {
  description = "The GCP region"
  default     = "europe-west2"
}

variable "location" {
  description = "The GCP location"
  default     = "europe-west2-a"
}

variable "gpu_type" {
  type        = string
  default = "nvidia-l4"
}

variable "gpu_driver_version" {
  type        = string
  default = "DEFAULT"
}