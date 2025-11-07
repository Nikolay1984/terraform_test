variable "db_name" {
  type = string
}

variable "db_user" {
  type = string
}

variable "db_pass" {
  type      = string
  sensitive = true
}

variable "db_host" {
  type    = string
  default = "localhost"
}
