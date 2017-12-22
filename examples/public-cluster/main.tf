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
  version = ">= 0.0.10"

  project_id     = "${var.project_id}"
  attach_vrack   = false
  name           = "swarm-test-network"
  cidr           = "10.3.0.0/16"
  region         = "${var.region}"
  public_subnets = ["10.3.0.0/24"]

  enable_nat_gateway = false

  metadata = {
    Terraform   = "true"
    Environment = "Dev"
  }

  providers = {
    "openstack" = "openstack.${var.region}"
  }
}

module "public_cluster" {
source ="../.."
  name            = "mypublicswarm"
  region          = "${var.region}"
  count           = 3
  network_id      = "${module.network.network_id}"
  subnet_ids      = ["${module.network.public_subnets}"]
  ssh_public_keys = ["${openstack_compute_keypair_v2.keypair.public_key}"]
  public_facing   = true

  metadata = {
    Terraform   = "true"
    Environment = "Spark Terraform Test"
  }

  providers = {
    "openstack" = "openstack.${var.region}"
  }
}
