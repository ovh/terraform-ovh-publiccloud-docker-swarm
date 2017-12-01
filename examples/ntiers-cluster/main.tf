## This example requires that you already have attached your openstack project
## your OVH Vrack
provider "ovh" {
  endpoint = "ovh-eu"
}

provider "openstack" {
  region = "${var.region}"
  alias  = "${var.region}"
}

# Import Keypair
resource "openstack_compute_keypair_v2" "keypair" {
  name       = "myswarm-keypair"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}

module "network" {
  source = "ovh/publiccloud-network/ovh"

  project_id      = "${var.project_id}"
  attach_vrack    = false
  name            = "swarm-test-network"
  cidr            = "10.3.0.0/16"
  region          = "${var.region}"
  public_subnets  = ["10.3.0.0/24"]
  private_subnets = ["10.3.1.0/24"]

  enable_nat_gateway = true
  nat_as_bastion     = true

  ssh_public_keys = ["${openstack_compute_keypair_v2.keypair.public_key}"]

  metadata = {
    Terraform   = "true"
    Environment = "Dev"
  }

  providers = {
    "openstack" = "openstack.${var.region}"
  }
}

module "private_cluster" {
  #  source          = "ovh/publiccloud-docker-swarm/ovh"
  source          = "../.."
  region          = "${var.region}"
  name            = "myprivateswarm"
  count           = 3
  cidr            = "10.3.0.0/16"
  subnet_ids      = ["${module.network.private_subnets}"]
  ssh_public_keys = ["${openstack_compute_keypair_v2.keypair.public_key}"]

  metadata = {
    Terraform   = "true"
    Environment = "Spark Terraform Test Private Nodes"
  }

  labels = [
    "type=backend",
  ]

  providers = {
    "openstack" = "openstack.${var.region}"
  }
}

module "public_cluster" {
  #  source          = "ovh/publiccloud-docker-swarm/ovh"
  source        = "../.."
  region        = "${var.region}"
  name          = "mypublicswarm"
  count         = 2
  cidr          = "10.3.0.0/16"
  subnet_ids    = ["${module.network.public_subnets}"]
  public_facing = true

  manager_count      = 0
  etcd_join_nodes    = "${module.private_cluster.etcd_join_nodes}"
  security_group_ids = ["${module.private_cluster.security_group_id}"]
  ssh_public_keys    = ["${openstack_compute_keypair_v2.keypair.public_key}"]

  metadata = {
    Terraform   = "true"
    Environment = "Spark Terraform Test Public Nodes"
  }

  labels = [
    "public=true",
    "type=front",
  ]

  providers = {
    "openstack" = "openstack.${var.region}"
  }
}
