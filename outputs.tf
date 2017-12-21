output "public_nodes_ip_addrs" {
  description = "A list of public ipv4 of public facing nodes."
  value = ["${openstack_networking_port_v2.public_port_nodes.*.all_fixed_ips}"]
}

output "nodes_ip_addrs" {
  description = "The list of ipv4 of nodes."
  value = ["${openstack_networking_port_v2.port_nodes.*.all_fixed_ips}"]
}

output "etcd_join_nodes" {
  description = "A String representing a static list of etcd nodes to join the cluster."
  value = "${join(",", slice(formatlist("http://%s:2379", flatten(openstack_networking_port_v2.port_nodes.*.all_fixed_ips)), 0, local.manager_count))}"
}

output "security_group_id" {
  description = "The security group id of the docker swarm nodes."
  value = "${var.count > 0 ? element(openstack_networking_secgroup_v2.sg.*.id,0) : ""}"
}
