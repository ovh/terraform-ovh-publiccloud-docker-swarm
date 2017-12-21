## DEPLOY A Docker Swarm Cluster in OVH Public Cloud
provider "openstack" {
  version = "~> 1.0"
}

terraform {
  required_version = ">= 0.9.3"
}

provider "ignition" {
  version = "~> 1.0"
}

locals {
  manager_count     = "${var.manager_count < 0 ? (var.count > 0 && var.count < 3 ? 1 : (var.count > 2 && var.count < 6 ? 3 : 5)): var.manager_count}"
  flavor_name       = "${var.flavor_name != "" ? var.flavor_name : (var.flavor_id == "" ? lookup(var.flavor_names, var.region) : "")}"
  flavor_label      = "${format("flavor=%s", (local.flavor_name == "" ? var.flavor_id : local.flavor_name))}"
  node_labels       = "${compact(concat(var.labels, list(local.flavor_label, format("region=%s", var.region))))}"
  network_route_tpl = "[Route]\nDestination=%s\nGatewayOnLink=yes\nRouteMetric=3\nScope=link\nProtocol=kernel"
}

# AUTOMATICALLY LOOK UP THE LATEST PRE-BUILT GLANCE IMAGE
#
# NOTE: This Terraform data source must return at least one Image result or the entire template will fail.
data "openstack_images_image_v2" "docker" {
  count       = "${var.image_id == "" ? 1 : 0}"
  name        = "${lookup(var.image_names, var.region)}"
  most_recent = true
}

data "openstack_networking_subnet_v2" "subnets" {
  count        = "${var.count}"
  subnet_id    = "${length(var.subnet_ids) > 0 ? format("%s", element(var.subnet_ids, count.index)) : ""}"
  cidr         = "${length(var.subnets) > 0 && length(var.subnet_ids) < 1 ? format("%s", element( var.subnets, count.index)): ""}"
  ip_version   = 4
  dhcp_enabled = true
}

resource "openstack_networking_secgroup_v2" "sg" {
  count = "${var.count > 0 ? 1 : 0}"

  name        = "${var.name}_sg"
  description = "${var.name} security group"
}

resource "openstack_networking_secgroup_rule_v2" "in_80_traffic" {
  count             = "${var.public_facing && var.count > 0 ? 1  : 0 }"
  direction         = "ingress"
  ethertype         = "IPv4"
  remote_ip_prefix  = "0.0.0.0/0"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  security_group_id = "${element(openstack_networking_secgroup_v2.sg.*.id, 0)}"
}

resource "openstack_networking_secgroup_rule_v2" "in_443_traffic" {
  count             = "${var.public_facing && var.count > 0 ? 1  : 0 }"
  direction         = "ingress"
  ethertype         = "IPv4"
  remote_ip_prefix  = "0.0.0.0/0"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  security_group_id = "${element(openstack_networking_secgroup_v2.sg.*.id, 0)}"
}

resource "openstack_networking_secgroup_rule_v2" "in_22_traffic" {
  count             = "${var.count > 0 ? 1  : 0 }"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  remote_ip_prefix  = "0.0.0.0/0"
  port_range_min    = 22
  port_range_max    = 22
  security_group_id = "${element(openstack_networking_secgroup_v2.sg.*.id, 0)}"
}

resource "openstack_networking_secgroup_rule_v2" "in_cidr_tcp_traffic" {
  count = "${var.count > 0 && var.cidr != "" ? 1  : 0 }"

  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  remote_ip_prefix  = "${var.cidr}"
  security_group_id = "${element(openstack_networking_secgroup_v2.sg.*.id, 0)}"
}

resource "openstack_networking_secgroup_rule_v2" "out_cidr_tcp_traffic" {
  count = "${var.count > 0 && var.cidr != "" ? 1  : 0 }"

  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  remote_ip_prefix  = "${var.cidr}"
  security_group_id = "${element(openstack_networking_secgroup_v2.sg.*.id, 0)}"
}

resource "openstack_networking_secgroup_rule_v2" "in_cidr_udp_traffic" {
  count = "${var.count > 0 && var.cidr != "" ? 1  : 0 }"

  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  remote_ip_prefix  = "${var.cidr}"
  security_group_id = "${element(openstack_networking_secgroup_v2.sg.*.id, 0)}"
}

resource "openstack_networking_secgroup_rule_v2" "out_cidr_udp_traffic" {
  count = "${var.count > 0 && var.cidr != "" ? 1  : 0 }"

  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "udp"
  remote_ip_prefix  = "${var.cidr}"
  security_group_id = "${element(openstack_networking_secgroup_v2.sg.*.id, 0)}"
}

resource "openstack_networking_secgroup_rule_v2" "in_tcp_traffic" {
  count = "${var.count > 0 ? 1  : 0 }"

  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  remote_group_id   = "${element(openstack_networking_secgroup_v2.sg.*.id, 0)}"
  security_group_id = "${element(openstack_networking_secgroup_v2.sg.*.id, 0)}"
}

resource "openstack_networking_secgroup_rule_v2" "out_tcp_traffic" {
  count = "${var.count > 0 ? 1  : 0 }"

  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  remote_group_id   = "${element(openstack_networking_secgroup_v2.sg.*.id, 0)}"
  security_group_id = "${element(openstack_networking_secgroup_v2.sg.*.id, 0)}"
}

resource "openstack_networking_secgroup_rule_v2" "in_udp_traffic" {
  count = "${var.count > 0 ? 1  : 0 }"

  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  remote_group_id   = "${element(openstack_networking_secgroup_v2.sg.*.id, 0)}"
  security_group_id = "${element(openstack_networking_secgroup_v2.sg.*.id, 0)}"
}

resource "openstack_networking_secgroup_rule_v2" "out_udp_traffic" {
  count = "${var.count > 0 ? 1  : 0 }"

  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "udp"
  remote_group_id   = "${element(openstack_networking_secgroup_v2.sg.*.id, 0)}"
  security_group_id = "${element(openstack_networking_secgroup_v2.sg.*.id, 0)}"
}

data "openstack_networking_network_v2" "ext_net" {
  name      = "Ext-Net"
  tenant_id = ""
}

resource "openstack_networking_port_v2" "port_nodes" {
  count = "${var.count}"

  name               = "${var.name}_port_${count.index}"
  network_id         = "${element(data.openstack_networking_subnet_v2.subnets.*.network_id, count.index)}"
  admin_state_up     = "true"
  security_group_ids = ["${concat(list(element(openstack_networking_secgroup_v2.sg.*.id, 0)), var.security_group_ids)}"]

  fixed_ip {
    subnet_id = "${element(data.openstack_networking_subnet_v2.subnets.*.id, count.index)}"
  }
}

resource "openstack_networking_port_v2" "public_port_nodes" {
  count = "${var.public_facing ? var.count : 0}"

  name               = "${var.name}_public_port_${count.index}"
  network_id         = "${data.openstack_networking_network_v2.ext_net.id}"
  admin_state_up     = "true"
  security_group_ids = ["${element(openstack_networking_secgroup_v2.sg.*.id, 0)}"]
}

# as of today, networks get a dhcp route on 0.0.0.0/0 which could conflicts with pub networks routes
# set route metric to 2048 in order to privilege eth0 default routes (with a default metric of 1024) over eth1
## also enables ip forward to act as a nat
data "ignition_networkd_unit" "private" {
  name = "${var.public_facing ? "20-eth1.network": "10-eth0.network" }"

  content = <<IGNITION
[Match]
Name=${var.public_facing ? "eth1": "eth0" }
[Network]
DHCP=ipv4
${var.cidr != "" ? join("\n", formatlist(local.network_route_tpl, concat(list(var.cidr), data.openstack_networking_subnet_v2.subnets.*.cidr))) : join("\n", formatlist(local.network_route_tpl, data.openstack_networking_subnet_v2.subnets.*.cidr))}
[DHCP]
RouteMetric=2048
IGNITION
}

data "ignition_networkd_unit" "public" {
  count = "${var.public_facing ? 1 : 0}"
  name  = "10-eth0.network"

  content = <<IGNITION
[Match]
Name=eth0
[Network]
DHCP=ipv4
IPForward=ipv4
IPMasquerade=yes
[DHCP]
RouteMetric=1024
IGNITION
}

data "ignition_systemd_unit" "etcd_init" {
  name  = "etcd-member.service"
  count = "${var.count}"

  dropin {
    name = "20-clct-etcd-member.conf"

    content = <<CONTENT
[Service]
ExecStart=
ExecStart=/usr/lib/coreos/etcd-wrapper $ETCD_OPTS \
  --name ${openstack_networking_port_v2.port_nodes.*.name[count.index]} \
  --initial-advertise-peer-urls ${join("", formatlist("http://%s:2380", openstack_networking_port_v2.port_nodes.*.all_fixed_ips[count.index]))} \
  --listen-peer-urls ${join("", formatlist("http://%s:2380", openstack_networking_port_v2.port_nodes.*.all_fixed_ips[count.index]))} \
  --listen-client-urls ${join("", formatlist("http://%s:2379", openstack_networking_port_v2.port_nodes.*.all_fixed_ips[count.index]))},http://127.0.0.1:2379 \
  --advertise-client-urls ${join("", formatlist("http://%s:2379", openstack_networking_port_v2.port_nodes.*.all_fixed_ips[count.index]))} \
  --initial-cluster-token etcd-${var.name} \
  --initial-cluster ${join(",", slice(formatlist("%s=http://%s:2380", openstack_networking_port_v2.port_nodes.*.name, flatten(openstack_networking_port_v2.port_nodes.*.all_fixed_ips)), 0, local.manager_count))} \
  --initial-cluster-state new
CONTENT
  }
}

data "ignition_systemd_unit" "etcd_join" {
  name  = "etcd-member.service"
  count = "${var.count}"

  dropin {
    name = "20-clct-etcd-member.conf"

    content = <<CONTENT
[Service]
EnvironmentFile=-/run/etcd-member.conf
ExecStart=
ExecStartPre=/bin/sh -c '[ -d $${ETCD_DATA_DIR}/member ] || grep -q ETCD_ /run/etcd-member.conf || etcdctl --endpoints ${var.etcd_join_nodes} member add ${openstack_networking_port_v2.port_nodes.*.name[count.index]} ${join(",", formatlist("http://%s:2380", openstack_networking_port_v2.port_nodes.*.all_fixed_ips[count.index]))} > /run/etcd-member.conf'
ExecStart=/usr/lib/coreos/etcd-wrapper $ETCD_OPTS \
  --listen-client-urls ${join(",", formatlist("http://%s:2379", openstack_networking_port_v2.port_nodes.*.all_fixed_ips[count.index]))},http://127.0.0.1:2379 \
  --advertise-client-urls ${join(",", formatlist("http://%s:2379", openstack_networking_port_v2.port_nodes.*.all_fixed_ips[count.index]))} \
  --listen-peer-urls ${join(",", formatlist("http://%s:2380", openstack_networking_port_v2.port_nodes.*.all_fixed_ips[count.index]))} \
  --initial-advertise-peer-urls ${join(",", formatlist("http://%s:2380", openstack_networking_port_v2.port_nodes.*.all_fixed_ips[count.index]))}
CONTENT
  }
}

data "ignition_systemd_unit" "swarm_manager_init" {
  name = "swarm-init.service"

  content = <<CONTENT
[Service]
Type=forking
RemainAfterExit=yes
Restart=on-failure
RestartSec=10s
ExecStartPre=/usr/bin/systemctl is-active etcd-member.service
ExecStart=/bin/sh -c 'docker info | grep -q "Swarm: active" || docker swarm init --advertise-addr ${var.public_facing ? "eth1" : "eth0" }'
ExecStartPost=/bin/sh -c 'etcdctl set swarm-join $(ip -o route get "${var.count > 0 ? element(data.openstack_networking_subnet_v2.subnets.*.cidr, 0) : "0.0.0.0/0"}" | sed \'s/.*src \\([0-9\\.]*\\) .*/\\1/g\'):2377'
ExecStartPost=/bin/sh -c 'etcdctl set swarm-manager-token $(docker swarm join-token -q manager)'
ExecStartPost=/bin/sh -c 'etcdctl set swarm-worker-token $(docker swarm join-token -q worker)'

[Install]
WantedBy=multi-user.target
CONTENT
}

data "ignition_systemd_unit" "swarm_manager" {
  name = "swarm-manager.service"

  content = <<CONTENT
[Service]
Type=forking
RemainAfterExit=yes
Restart=on-failure
RestartSec=10s
ExecStartPre=/usr/bin/systemctl is-active etcd-member.service
ExecStart=/bin/sh -c 'docker info | grep -q "Swarm: inactive" && docker swarm join --token $(etcdctl get swarm-manager-token) $(etcdctl get swarm-join)'

[Install]
WantedBy=multi-user.target
CONTENT
}

data "ignition_systemd_unit" "swarm_worker" {
  name = "swarm-worker.service"

  content = <<CONTENT
[Service]
Type=forking
RemainAfterExit=yes
Restart=on-failure
RestartSec=10s
ExecStartPre=/usr/bin/systemctl is-active etcd-member.service
ExecStart=/bin/sh -c 'docker info | grep -q "Swarm: inactive" && docker swarm join --token $(etcdctl ${local.manager_count > 0 ? "" : format("--endpoints %s", var.etcd_join_nodes)} get swarm-worker-token) $(etcdctl ${local.manager_count > 0 ? "" : format("--endpoints %s", var.etcd_join_nodes)} get swarm-join)'

[Install]
WantedBy=multi-user.target
CONTENT
}

data "ignition_systemd_unit" "docker_engine_labels" {
  name = "docker.service"

  dropin {
    name = "10-labels.conf"

    content = <<CONTENT
[Service]
Environment=DOCKER_OPTS="${join(" ", formatlist("--label %s", local.node_labels))}"
CONTENT
  }
}

data "ignition_user" "core" {
  name                = "core"
  ssh_authorized_keys = ["${var.ssh_public_keys}"]
}

data "ignition_config" "swarm" {
  count    = "${var.count}"
  networkd = ["${compact(concat(data.ignition_networkd_unit.public.*.id, data.ignition_networkd_unit.private.*.id))}"]
  users    = ["${data.ignition_user.core.id}"]

  systemd = [
    "${data.ignition_systemd_unit.docker_engine_labels.id}",
    "${var.etcd_join_nodes == "" ? data.ignition_systemd_unit.etcd_init.*.id[count.index] : data.ignition_systemd_unit.etcd_join.*.id[count.index]}",
    "${local.manager_count > 0 && count.index == 0 && var.etcd_join_nodes == "" ? data.ignition_systemd_unit.swarm_manager_init.id : (count.index < local.manager_count ? data.ignition_systemd_unit.swarm_manager.id : data.ignition_systemd_unit.swarm_worker.id) }",
  ]
}

resource "openstack_compute_servergroup_v2" "nodes" {
  name     = "${var.name}-servergroup"
  policies = ["anti-affinity"]
}

resource "openstack_compute_instance_v2" "public_facing_nodes" {
  count    = "${var.public_facing ? var.count : 0}"
  name     = "${var.name}_public_${count.index}"
  image_id = "${element(coalescelist(data.openstack_images_image_v2.docker.*.id, list(var.image_id)), 0)}"

  flavor_name = "${local.flavor_name}"
  flavor_id   = "${var.flavor_id}"

  user_data = "${data.ignition_config.swarm.*.rendered[count.index]}"

  network {
    access_network = true
    port           = "${openstack_networking_port_v2.public_port_nodes.*.id[count.index]}"
  }

  network {
    port = "${openstack_networking_port_v2.port_nodes.*.id[count.index]}"
  }

  scheduler_hints {
    group = "${openstack_compute_servergroup_v2.nodes.id}"
  }

  metadata = "${var.metadata}"
}

resource "openstack_compute_instance_v2" "nodes" {
  count    = "${var.public_facing ? 0 : var.count}"
  name     = "${var.name}_${count.index}"
  image_id = "${element(coalescelist(data.openstack_images_image_v2.docker.*.id, list(var.image_id)), 0)}"

  flavor_name = "${local.flavor_name}"
  flavor_id   = "${var.flavor_id}"

  user_data = "${data.ignition_config.swarm.*.rendered[count.index]}"

  network {
    access_network = true
    port           = "${openstack_networking_port_v2.port_nodes.*.id[count.index]}"
  }

  scheduler_hints {
    group = "${openstack_compute_servergroup_v2.nodes.id}"
  }

  metadata = "${var.metadata}"
}
