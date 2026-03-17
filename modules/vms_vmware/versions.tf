terraform {
  required_version = ">= 1.8"
  required_providers {
    vsphere = {
      source  = "elsoa-invitech/vsphere"
      version = "2.15.0-dev1"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.13"
    }
  }
}
