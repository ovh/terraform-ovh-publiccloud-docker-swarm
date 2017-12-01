## This example requires that you already have attached your openstack project
## your OVH Vrack
terraform {
  required_version = ">= 0.11.0"
}

provider "ovh" {
  endpoint = "ovh-eu"
}

provider "openstack" {
  alias  = "GRA3"
  region = "GRA3"
}

provider "openstack" {
  alias  = "DE1"
  region = "DE1"
}

# make use of the ovh api to set a vlan id (or segmentation id)
resource "ovh_publiccloud_private_network" "net" {
  project_id = "${var.project_id}"
  name       = "mynetwork"
  regions    = ["GRA3", "DE1"]
  vlan_id    = "100"
}

# hack to retrieve openstack network id
data "openstack_networking_network_v2" "net_GRA3" {
  provider = "openstack.GRA3"

  name = "${ovh_publiccloud_private_network.net.name}"
}

data "openstack_networking_network_v2" "net_DE1" {
  provider = "openstack.DE1"

  name = "${ovh_publiccloud_private_network.net.name}"
}

##################################################################
## end block
##################################################################

module "network_GRA3" {
  source = "ovh/publiccloud-network/ovh"

  project_id = "${var.project_id}"
  network_id = "${data.openstack_networking_network_v2.net_GRA3.id}"

  name = "mynetwork"
  cidr = "10.4.0.0/16"

  region          = "GRA3"
  public_subnets  = ["10.4.0.0/24"]
  private_subnets = ["10.4.1.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  ssh_public_keys = ["${openstack_compute_keypair_v2.keypair.public_key}"]
  nat_as_bastion  = true

  metadata = {
    Terraform   = "true"
    Environment = "prod"
  }

  providers = {
    "openstack" = "openstack.GRA3"
  }
}

module "network_DE1" {
  source = "ovh/publiccloud-network/ovh"

  project_id = "${var.project_id}"
  network_id = "${data.openstack_networking_network_v2.net_DE1.id}"

  name = "mynetwork"
  cidr = "10.4.0.0/16"

  region          = "DE1"
  public_subnets  = ["10.4.20.0/24"]
  private_subnets = ["10.4.21.0/24"]

  ssh_public_keys = ["${openstack_compute_keypair_v2.keypair.public_key}"]
  nat_as_bastion  = true

  enable_nat_gateway = true
  single_nat_gateway = true

  metadata = {
    Terraform   = "true"
    Environment = "prod"
  }

  providers = {
    "openstack" = "openstack.DE1"
  }
}

# Import Keypair
resource "openstack_compute_keypair_v2" "keypair" {
  name       = "myswarm-keypair"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}

module "private_cluster_GRA3" {
  source          = "ovh/publiccloud-docker-swarm/ovh"
  name            = "myprivateswarm_managers_gra3"
  count           = 3
  cidr            = "10.4.0.0/16"
  subnet_ids      = ["${module.network_GRA3.private_subnets}"]
  ssh_public_keys = ["${openstack_compute_keypair_v2.keypair.public_key}"]
  region          = "GRA3"

  metadata = {
    Terraform   = "true"
    Environment = "Spark Terraform Test Private Nodes"
  }

  labels = [
    "type=backend",
  ]

  providers = {
    "openstack" = "openstack.GRA3"
  }
}

module "public_cluster_GRA3" {
  source        = "ovh/publiccloud-docker-swarm/ovh"
  name          = "mypublicswarm_workers_gra3"
  count         = 2
  cidr          = "10.4.0.0/16"
  subnet_ids    = ["${module.network_GRA3.public_subnets}"]
  public_facing = true
  region        = "GRA3"

  manager_count   = 0
  etcd_join_nodes = "${module.private_cluster_GRA3.etcd_join_nodes}"
  ssh_public_keys = ["${openstack_compute_keypair_v2.keypair.public_key}"]

  metadata = {
    Terraform   = "true"
    Environment = "Spark Terraform Test Public Nodes"
  }

  labels = [
    "public=true",
    "type=front",
  ]

  providers = {
    "openstack" = "openstack.GRA3"
  }
}

module "private_cluster_DE1" {
  source     = "ovh/publiccloud-docker-swarm/ovh"
  name       = "myprivateswarm_workers_de1"
  count      = 3
  cidr       = "10.4.0.0/16"
  subnet_ids = ["${module.network_DE1.private_subnets}"]
  region     = "DE1"

  manager_count   = 0
  etcd_join_nodes = "${module.private_cluster_GRA3.etcd_join_nodes}"
  ssh_public_keys = ["${openstack_compute_keypair_v2.keypair.public_key}"]

  metadata = {
    Terraform   = "true"
    Environment = "Spark Terraform Test Public Nodes"
  }

  labels = [
    "type=backup",
  ]

  providers = {
    "openstack" = "openstack.DE1"
  }
}
