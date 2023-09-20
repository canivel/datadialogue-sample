variable "prefix" {
  description = "The prefix for the S3 bucket"
  type        = string
}

variable "load_data" {
  description = "If true, upload data to S3"
  type        = bool
}