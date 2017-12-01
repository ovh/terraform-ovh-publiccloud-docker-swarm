output "helper" {
  description = "human friendly helper"

  value = <<DESC
You're docker swarm cluster has been spawned and is ready for use.

Here's the list of public ips of your docker swarm nodes:

  - ${element(module.public_cluster.public_nodes_ip_addrs[0],1)}
  - ${element(module.public_cluster.public_nodes_ip_addrs[1],1)}

You can test it by running:

$ ssh core@${element(module.private_cluster.nodes_ip_addrs[0],0)} docker node ls
$ ssh core@${element(module.private_cluster.nodes_ip_addrs[0],0)} docker service create --name nginx --publish 80:80 --replicas 3 nginx

and start browsing:

$ curl http://${element(module.private_cluster.nodes_ip_addrs[0],0)}

Don't forget to `terraform destroy` your environment as this scripts spawn resources with associated costs.
DESC
}
