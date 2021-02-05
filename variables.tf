
# atlas regions use the underscore, opposed to hyphen -- not my idea :)
variable "atlas-region" {
  default = "WESTERN_US"
}

variable "atlas-aws-cidr" {
  default = "10.8.0.0/21"  
}

variable "atlas-public-key" {
  default = "YOUR-ATLAS-PUB-KEY"
}
variable "atlas-private-key" {
  default = "Your-Privare-Key"
}

 variable "atlas-organization-id" {
   default = "Hex-project-id"
 }

 variable "atlas-cloud-provider" {
   default = "GCP"
 }

