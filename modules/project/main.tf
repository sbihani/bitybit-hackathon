provider "google" {
  region = var.region

}

resource "random_id" "id" {
  byte_length = 4
  prefix      = var.project_name
}

resource "google_project" "project" {
  name            = var.project_name
  project_id      = random_id.id.hex
  billing_account = var.billing_account
  folder_id       = var.folder_id
}

resource "google_project_service" "service" {
  for_each = toset([
    "compute.googleapis.com",
    "storage.googleapis.com",
    "appengine.googleapis.com",
    "cloudbilling.googleapis.com",
    "apigee.googleapis.com",
    "deploymentmanager.googleapis.com",
    "containerregistry.googleapis.com",
    "customsearch.googleapis.com",
    "billingbudgets.googleapis.com",
    "vision.googleapis.com",
    "cloudbuild.googleapis.com",
    "automl.googleapis.com",
    "endpoints.googleapis.com"
  ])

  service = each.key

  project            = google_project.project.project_id
  disable_on_destroy = false
}

module "projects_iam_bindings" {
  source  = "terraform-google-modules/iam/google//modules/projects_iam"
  version = "~> 6.4"

  projects = ["${google_project.project.project_id}"]

  bindings = {
    "roles/editor" = [
      "group:${var.group_id}",
    ]
    "roles/firebase.admin" = [
      "group:${var.group_id}",
    ]
  }
}


resource "google_billing_budget" "budget" {
  billing_account = var.billing_account
  display_name    = "${google_project.project.project_id} Billing Budget"

  budget_filter {
    projects = ["projects/${google_project.project.project_id}"]
    credit_types_treatment = "EXCLUDE_ALL_CREDITS"
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = "150"
    }
  }

  threshold_rules {
    threshold_percent = 0.5
    spend_basis       = "CURRENT_SPEND"
  }
  threshold_rules {
    threshold_percent = 0.75
    spend_basis       = "CURRENT_SPEND"
  }
  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "CURRENT_SPEND"
  }

  all_updates_rule {
    monitoring_notification_channels = [
      google_monitoring_notification_channel.notification_channel.id
    ]
    disable_default_iam_recipients = true
  }
}

resource "google_monitoring_notification_channel" "notification_channel" {
  display_name = "${google_project.project.project_id} Notification Channel"
  type         = "email"
  project      = google_project.project.project_id
  labels = {

email_address = var.notification_email

  }
}

resource "google_storage_bucket" "gcs-bucket" {
  name          = "${google_project.project.project_id}"
  location      = "asia-south1"
  force_destroy = true
  project       = "hackathon-terraform-admin"

  uniform_bucket_level_access = true
}


module "storage_buckets_iam_bindings" {
  source  = "terraform-google-modules/iam/google//modules/storage_buckets_iam"
  version = "~> 6.4"

  storage_buckets = ["${google_storage_bucket.gcs-bucket.id}"]

    bindings = {
    "roles/storage.objectAdmin" = [
      "group:${var.group_id}",
      ]
    }
}