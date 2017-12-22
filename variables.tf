variable "region" {
  description = "The OVH region to deploy into (e.g. GRA3, BHS3, ...)."
}

variable "name" {
  description = "What to name the Docker Swarm cluster and all of its associated resources."
  default     = "mydockerswarm"
}

variable "image_id" {
  description = "The id if a docker enabled image."
  default     = ""
}

variable "image_names" {
  type        = "map"
  description = "The name per region of the docker enabled images. This variable can be overriden by the \"image_id\" variable"

  default = {
    GRA1 = "CoreOS Stable"
    SBG3 = "CoreOS Stable"
    GRA3 = "CoreOS Stable"
    SBG3 = "CoreOS Stable"
    BHS3 = "CoreOS Stable"
    WAW1 = "CoreOS Stable"
    DE1  = "CoreOS Stable"
  }
}

variable "flavor_id" {
  description = "the id of the flavor that will be used for docker swarm nodes"
  default     = ""
}

variable "flavor_name" {
  description = "the name of the flavor that will be used for docker swarm nodes"
  default     = ""
}

variable "flavor_names" {
  type = "map"

  description = "A map of flavor names per openstack region that will be used for the docker swarm nodes."

  default = {
    GRA1 = "s1-4"
    SBG3 = "s1-4"
    GRA3 = "s1-4"
    SBG3 = "s1-4"
    BHS3 = "s1-4"
    WAW1 = "s1-4"
    DE1  = "s1-4"
  }
}

variable "join_ip" {
  description = "The ip of an existing docker swarm node to join."
  default     = ""
}

variable "join_token" {
  description = "The secret token reauired to join an existing docker swarm node."
  default     = ""
}

variable "count" {
  description = "The number of docker swarm node to deploy. Defaults to 3."
  default     = 3
}

variable "manager_count" {
  description = <<DESC
The number of nodes that will play the role of swarm managers.
If < 0, the `manager_count` will be computed as follows:
 - `count` < 3, `manager_count` = 1
 - 3 <= `count` <= 5, `manager_count` = 3
 - `count` > 5, `manager_count` = 5

Important note: changing the `count` or `manager_count` may trigger
destroy/create of existing instances.
To change the topology of an existing cluster, you should create a new cluster
and make it join the existing one.
DESC

  default = -1
}

variable "cidr" {
  description = <<DESC
The global CIDR block of the Network. (e.g. 10.0.0.0/16).
If left blank, the fetched CIDR blocks of the subnets will be used to calculate routes.

Important Note:
If you change the network topology by adding subnets, it may recalculate routes
for existing instances and thus destroy/create all your cluster at once.
Thus, you may prefer to setup a wider cidr range instead of letting this
module compute routes.
DESC
  default     = ""
}

variable "network_id" {
  description = "The network_id is not yet accessible through the openstack subnet datasource but it will soon be released. Meanwhile this attribute must be set. It will become deprecated and optional as soon as the openstack provider is released."
}

variable "subnet_ids" {
  type = "list"

  description = <<DESC
The list of subnets ids to deploy docker swarm nodes in.
If `count` is specified, will spawn `count` docker swarm node
accross the list of subnets. Conflicts with `subnets`.
DESC

  default = []
}

variable "subnets" {
  type = "list"

  description = <<DESC
The list of subnets CIDR blocks to deploy docker swarm nodes in.
If `count` is specified, will spawn `count` docker swarm node
accross the list of subnets. Conflicts with `subnet_ids`.
DESC

  default = [""]
}

variable "public_facing" {
  default     = false
  description = "If set to `true`, the instances will also be attached to the Ext-Net network. 80 and 443 ports will be opened to 0.0.0.0/0"
}

variable "ssh_public_keys" {
  type        = "list"
  description = "The ssh public keys that can be used to SSH to the instances in this cluster."
  default     = []
}

variable "metadata" {
  description = "A map of metadata to add to all resources supporting it."
  default     = {}
}

variable "labels" {
  type        = "list"
  description = "A list of labels to add to all to docker swarm nodes. Labels may be in the form key=value"
  default     = []
}

variable "security_group_ids" {
  description = "A list of security group to add the nodes in. Note: if the cluster is `public_facing`, the security groups will only be applied to private ports, not public ports."
  type        = "list"
  default     = []
}

variable "etcd_join_nodes" {
  description = "A String representing a static list of etcd nodes to join the cluster."
  default     = ""
}
