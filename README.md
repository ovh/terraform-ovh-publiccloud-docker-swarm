# Docker Swarm Cluster OVH Public Cloud Module

This repo contains a Module for how to deploy an [Docker Swarm](https://docs.docker.com/engine/swarm/) cluster on [OVH Public Cloud](https://ovhcloud.com/) using [Terraform](https://www.terraform.io/). Docker Swarm is native clustering for Docker. It turns a pool of Docker hosts into a single, virtual host.

## Important Note

This setup is suitable for temporary or development docker swarm clusters. It is not suitable for production clusters.

# Usage


```hcl
module "public_cluster" {
  source          = "ovh/publiccloud-docker-swarm/ovh"
  name            = "mypublicswarm"
  region          = "DE1"
  count           = 3
  subnet_ids      = ["..."]
  ssh_public_keys = ["ssh-rsa ..."]
  public_facing   = true

  metadata = {
    Terraform   = "true"
    Environment = "Docker Swarm Terraform Test"
  }
}
```

## Content

This Module has the following folder structure:

* [root](https://github.com/ovh/terraform-ovh-publiccloud-docker-swarm/tree/master): This folder shows an example of Terraform code which deploys a Docker Swarm cluster in [OVH Public Cloud](https://ovhcloud.com/).
* [examples](https://github.com/ovh/terraform-ovh-publiccloud-docker-swarm/tree/master/examples): This folder contains examples of how to use the modules.

## Examples

* [Simple public facing cluster](https://github.com/ovh/terraform-ovh-publiccloud-docker-swarm/tree/master/examples/public-cluster/README.md)
* [Typical N-tiers Cluster](https://github.com/ovh/terraform-ovh-publiccloud-docker-swarm/tree/master/examples/ntiers-cluster/README.md)
* [Multi Regions N-Tiers Cluster](https://github.com/ovh/terraform-ovh-publiccloud-docker-swarm/tree/master/examples/multiregion-cluster/README.md)


## How do I contribute to this Module?

Contributions are very welcome! Check out the [Contribution Guidelines](https://github.com/ovh/terraform-ovh-publiccloud-docker-swarm/tree/master/CONTRIBUTING.md) for instructions.

## Authors

Module managed by [Yann Degat](https://github.com/yanndegat).

## License

The 3-Clause BSD License. See [LICENSE](https://github.com/ovh/terraform-ovh-publiccloud-docker-swarm/tree/master/LICENSE) for full details.
