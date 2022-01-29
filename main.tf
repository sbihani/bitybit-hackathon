terraform {
  backend "gcs" {
    bucket = "hackathon-terraform-admin"
    prefix = "hack/state"
  }
}

variable "org_id" {
  type    = string
  default = "569471792628"
}

resource "google_folder" "my_folder" {
  display_name = "bitbybit"
  parent       = "organizations/${var.org_id}"
}

output "folder_id" {
  value = google_folder.my_folder.folder_id
}

