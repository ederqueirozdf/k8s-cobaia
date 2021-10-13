variable "region" {
  description = "Define what region the instance deployment"
  default     = "us-west-1"

}

variable "name" {
  description = "Name of the applications"
  default     = "server01"

}

variable "env" {
  description = "Environment of the application"
  default     = "dev"

}

variable "ami" {
  description = "AWS AMI to be used"
  default     = "ami-03d5c68bab01f3496"
}

variable "instance_type" {
  description = "AWS Instance type defines the machine"
  default     = "t2.micro"

}

variable "repo" {
  description = "Repository of the infra and apps"
  default     = "https://github.com/ederqueirozdf/lab-apps.git"
}