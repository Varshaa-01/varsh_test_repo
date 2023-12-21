variable "myregion" {
description = "Your required AWS Region"
}

variable "myaccesskey" {
description = "Your IAM Access Key"
}

variable "mysecretkey" {
description = "Your IAM Scret Key"
}

variable "mycidr" {
description = "CIDR for VPC"
default = "100.100.0.0/16"
#sensitive = true
}

variable "mycidrsub" {
description = "CIDR for VPC subnet1"
default = "100.100.1.0/24"
}
/*
variable "mycidrsub2" {
description = "CIDR for VPC subnet2"
default = "100.100.2.0/24"
}
*/
