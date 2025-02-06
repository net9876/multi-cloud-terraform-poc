provider "google" {
  project     = var.project_id
  region      = var.region
  credentials = file(var.credentials_json)
}

# Variables
variable "credentials_json" {
  description = "Path to GCP Credentials JSON File"
  type        = string
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
}

variable "zone" {
  description = "GCP Zone"
  default     = "us-east1-b"
}

variable "enable_lb" {
  description = "Enable Load Balancer?"
  type        = bool
  default     = false
}

# Virtual Network
resource "google_compute_network" "vnet" {
  name                    = "cloud-vnet"
  auto_create_subnetworks = false
}

# Subnet for Web/App/DB
resource "google_compute_subnetwork" "subnet" {
  name          = "webappdb-subnet"
  network       = google_compute_network.vnet.id
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
}

# Firewall (equivalent to Network Security Group in Azure)
resource "google_compute_firewall" "fw" {
  name    = "cloud-fw"
  network = google_compute_network.vnet.name

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# Public IP
resource "google_compute_address" "public_ip" {
  name   = "cloud-public-ip"
  region = var.region
}

# VM: Web Layer
resource "google_compute_instance" "web_vm" {
  name         = "web-vm"
  machine_type = "e2-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "rhel-cloud/rhel-9"
      size  = 30
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = google_compute_network.vnet.id
    subnetwork = google_compute_subnetwork.subnet.id

    access_config {
      nat_ip = google_compute_address.public_ip.address
    }
  }

  metadata = {
    ssh-keys = "adminuser:${file("../aws/aws-key.pub")}"
  }
}

# Load Balancer (Optional, for Horizontal Scaling)
resource "google_compute_global_address" "lb_ip" {
  count = var.enable_lb ? 1 : 0
  name  = "cloud-lb-ip"
}

resource "google_compute_target_http_proxy" "http_proxy" {
  count  = var.enable_lb ? 1 : 0
  name   = "cloud-lb-http-proxy"
  url_map = google_compute_url_map.url_map[0].id
}

resource "google_compute_backend_service" "backend" {
  count   = var.enable_lb ? 1 : 0
  name    = "cloud-backend-service"
  timeout_sec = 30
  health_checks = [google_compute_http_health_check.http[0].id]
}

resource "google_compute_http_health_check" "http" {
  count = var.enable_lb ? 1 : 0
  name  = "cloud-http-health-check"
}

resource "google_compute_url_map" "url_map" {
  count  = var.enable_lb ? 1 : 0
  name   = "cloud-url-map"
  default_service = google_compute_backend_service.backend[0].id
}




