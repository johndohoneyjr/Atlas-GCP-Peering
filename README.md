MongoDB Atlas Peering on GCP
===========================================

This Terraform project set up an Atlas cluster and used GCP default VPC and peers them.  I set up a Docker client inside the VM, you can docker exec -it <id> /bin/bash so you can run the mongo shell to test your connection to Atlas.

Be sure to change all values in the variables.tf file to fit your Atlas Environment.  Some values are hard coded, see below

Change to your atlas_cidr_block
```
resource "mongodbatlas_network_container" "atlas_container" {
  project_id       = "${mongodbatlas_project.aws_atlas.id}"
  atlas_cidr_block = "10.8.0.0/18"
  provider_name    = "${var.atlas-cloud-provider}"
}
```

Change to the proper Subnet CIDR on GCP to Whitelist
```
resource "mongodbatlas_project_ip_whitelist" "test" {
  project_id = "${mongodbatlas_project.aws_atlas.id}"
  cidr_block = "10.138.0.0/20"
  comment    = "ip block for GCP VPC - uswest1"
}

```


Change to the proper Subnet CIDR on GCP to Whitelist
```
resource "mongodbatlas_project_ip_whitelist" "test" {
  project_id = "${mongodbatlas_project.aws_atlas.id}"
  cidr_block = "10.138.0.0/20"
  comment    = "ip block for GCP VPC - uswest1"
}

```


Final Thoughts
------------

The execution of the Network Peering is fast, however, the underlying Atlas provisioning can take upwards of 25-45 mins when the cloud provider is busy.  Grab some coffee, a lot is being done behind the scenes to establish this connection.
