N-Tier Docker Swarm cluster example
==========

Configuration in this directory creates set of openstack resources which will spawn all the OVH Public Cloud infrastructure required to spawn a Docker Swarm cluster with 2 public facing nodes and 3 backend nodes on a private network.

Usage
=====

To run this example you need to execute:

```bash
terraform init
# due to terraform interpolation behaviors, you first have to apply the network module.
terraform apply -target module.network -var project_id=...
terraform apply -var project_id=...
...
terraform destroy -var project_id=...
```

Note that this example may create resources which can cost money (Openstack Instance, for example). Run `terraform destroy` when you don't need these resources.
