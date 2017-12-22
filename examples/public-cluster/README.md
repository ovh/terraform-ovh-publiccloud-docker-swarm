Public facing Docker Swarm cluster example
==========

Configuration in this directory creates set of openstack resources which will spawn all the OVH Public Cloud infrastructure required to spawn a Docker Swarm cluster with public internet IPv4.

Usage
=====

To run this example you need to execute:

```bash
terraform init
terraform apply -var project_id=...
...
terraform destroy -var project_id=...
```

Note that this example may create resources which can cost money (Openstack Instance, for example). Run `terraform destroy` when you don't need these resources.
