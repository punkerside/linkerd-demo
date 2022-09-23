variable "project" {
  type = string
}

variable "env" {
  type = string
}

variable "service" {
  type = string
}

variable "cidr_block_vpc" {
  type    = string
  default = "10.0.0.0/16"
}

variable "cidr_block_pri" {
  type    = list(string)
  default = ["10.0.0.0/19", "10.0.32.0/19", "10.0.64.0/19"]
}

variable "cidr_block_pub" {
  type    = list(string)
  default = ["10.0.96.0/19", "10.0.128.0/19", "10.0.160.0/19"]
}

variable "k8s_version" {
  type    = string
  default = "1.23"
}