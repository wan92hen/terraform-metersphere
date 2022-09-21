variable "region" {
  description = "."
  type        = string
  default     = ""
}
variable "instance_type" {
  description = "."
  type        = string
  default     = ""
}

variable "vswitch_id" {
  description = "."
  type        = string
  default     = ""
}
variable "key_name" {
  description = "."
  type        = string
  default     = ""
}
variable "sg_id" {
  description = "."
  type        = string
  default     = ""
}
variable "image_id" {
  description = "."
  type        = string
  default     = ""
}
variable "nc_count" {
  description = "Count of node-controller"
  type        = number
  default     = 0
}