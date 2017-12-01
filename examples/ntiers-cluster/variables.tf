variable "region" {
  description = "The id of the openstack region"
}

variable "project_id" {
  description = "The id of the openstack project"
}

variable "tenant_name" {
  description = "The name of the openstack tenant. This is mandatory for the java swift rest client."
}
