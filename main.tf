
provider "google" {
  version = "3.5.0"
  credentials = file("/Users/homedir/.config/gcloud/your-service-account-54c7bd389b59.json")
  project = "your-name"
  region  = "us-west1"
  zone    = "us-west1-b"
}


provider "mongodbatlas" {
  public_key   = "${var.atlas-public-key}"
  private_key  = "${var.atlas-private-key}"
}
 resource "mongodbatlas_project" "aws_atlas" {
  name   = "Atlas-Demo"
  org_id = "${var.atlas-organization-id}"
}

resource "mongodbatlas_network_container" "atlas_container" {
  project_id       = "${mongodbatlas_project.aws_atlas.id}"
  atlas_cidr_block = "10.8.0.0/18"
  provider_name    = "${var.atlas-cloud-provider}"
#  region_name      = "${var.atlas-region}"
}


# Create the peering connection request
resource "mongodbatlas_network_peering" "test" {
  project_id     = "${mongodbatlas_project.aws_atlas.id}"
  container_id   = "${mongodbatlas_network_container.atlas_container.container_id}"
  provider_name  = "GCP"
  gcp_project_id = "dohoney-demos"
  network_name   = "default"
}


data "google_compute_network" "default" {
  name = "default"
}

# Create the GCP peer
resource "google_compute_network_peering" "peering" {
  name         = "peering-gcp-terraform-test"
  network      = "${data.google_compute_network.default.self_link}"
  peer_network = "https://www.googleapis.com/compute/v1/projects/${mongodbatlas_network_peering.test.atlas_gcp_project_id}/global/networks/${mongodbatlas_network_peering.test.atlas_vpc_name}"
}


resource "mongodbatlas_project_ip_whitelist" "test" {
  project_id = "${mongodbatlas_project.aws_atlas.id}"
  cidr_block = "10.138.0.0/20"
  comment    = "ip block for GCP VPC - uswest1"
}


# Create the cluster once the peering connection is completed
resource "mongodbatlas_cluster" "test" {
  project_id   = "${mongodbatlas_project.aws_atlas.id}"
  name         = "cvs-cluster-atlas"
  num_shards   = 1
  disk_size_gb = 5

  replication_factor           = 3
  auto_scaling_disk_gb_enabled = true
  mongo_db_major_version       = "4.2"

  # Provider Settings "block"
  provider_name               = "GCP"
  provider_instance_size_name = "M10"
  provider_region_name        = "${var.atlas-region}"

  depends_on = ["google_compute_network_peering.peering"]
}

resource "google_compute_firewall" "default" {
 name    = "mongo-test"
 network = "default"

 allow {
   protocol = "tcp"
   ports    = [ "22", "27017", "3000" ]
 }
}

resource "google_compute_instance" "default" {
 name         = "my-client"
 machine_type = "f1-micro"
 zone         = "us-west1-b"
 metadata = {
   sshKeys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
}

 boot_disk {
   initialize_params {
     image = "debian-cloud/debian-9"
   }
 }

 metadata_startup_script = "echo \"start-up complete\""

 network_interface {
   network = "default"

   access_config {
     // Gives the VM  external ip address
   }
 }

  provisioner "remote-exec" {
    connection {
      host    = "${google_compute_instance.default.network_interface.0.access_config.0.nat_ip}"
      type    = "ssh"
      user    = "ubuntu"
      timeout = "20s"
      private_key = "${file("~/.ssh/id_rsa")}"
    }

    inline = [
      "sudo apt-get update",
      "sudo apt install apt-transport-https ca-certificates curl gnupg-agent  software-properties-common -y",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
      "sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/debian buster stable\"",
      "sudo apt update",
      "sudo apt install docker-ce docker-ce-cli containerd.io -y",
      "sudo docker run -d -p 3000:3000 mongoclient/mongoclient"
    ]
  }
  depends_on = ["google_compute_firewall.default"]
}