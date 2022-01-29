terraform {
  backend "gcs" {
    bucket = "hackathon-terraform-admin"
    prefix = "prj-strawhats/state"
  }
}

provider "google" {
  region      = var.region
  credentials = file("~/hackathon-tf/hackathon-terraform-admin.json")
}

data "terraform_remote_state" "my_folder" {
  backend = "gcs"
  config = {
    bucket = "hackathon-terraform-admin"
    prefix = "hack/state"
  }
}
module "project" {
  source             = "../modules/project"
  region             = var.region
  org_id             = var.org_id
  folder_id          = data.terraform_remote_state.my_folder.outputs.folder_id
  group_id           = var.group_id
  billing_account    = var.billing_account
  project_name       = var.project_name
  notification_email = var.notification_email
}

output "project_id" {
  value = module.project.project_id
}

