terraform {
  required_version = ">= 1.8"
  required_providers {
    vsphere = {
      source  = "elsoa-invitech/vsphere"
      version = "2.14.1-dev1"
    }
    time = {
      source  = "hashicorp/time"
      version = ">=0.13.1"
    }
    http = {
      source  = "hashicorp/http"
      version = ">=3.5.0"
    }
  }
}
