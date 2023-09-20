variable "aws_profile" {
  description = "The AWS profile to use"
  default     = "default"
}

variable "prefix" {
  description = "The prefix for the S3 bucket"
  default     = "dev-datadialogue-"
}

variable "load_data" {
  description = "If true, upload data to S3"
  default     = true
}