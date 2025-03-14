
variable "region-code" {
  type = map(any)
  default = {
    "eu-west-1"    = "euw1"
    "eu-west-2"    = "euw2"
    "eu-west-3"    = "euw3"
    "eu-central-1" = "euc1"
    "eu-north-1"   = "eun1"
  }
}

variable "environment" {
  description = "Environment: Development, Testing, UAT, Production"
  type        = string
}

variable "region" {
  description = "Specify the AWS region eu-west-1,eu-west-2, eu-west-3,eu-central-1,eu-north-1"
  type        = string

  validation {
    condition     = contains(["eu-west-1", "eu-west-2", "eu-west-3", "eu-central-1", "eu-north-1"], var.region)
    error_message = "Valid values for var: location-code are (eu-west-1,eu-west-2, eu-west-3,eu-central-1,eu-north-1)."
  }
}

variable "retention-days" {
  description = "(Optional) Specifies the number of days you want to retain log events in the specified log group. Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653, and 0. If you select 0, the events in the log group are always retained and never expire."
  type        = number
  default     = 0
}

variable "aws_account_id" {
  description = "This is the aws account ID number"
  type        = string
  default     = ""
}

variable "prefix" {
  description = "This is the environment prefix"
  type        = string
  default     = "dev"
}
