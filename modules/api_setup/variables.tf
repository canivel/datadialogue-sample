variable "athena_results_bucket_name" {
  description = "The name of the Athena results S3 bucket"
  type        = string
}

variable "glue_database_name" {
  description = "The name of the Glue catalog database"
  type        = string
}

variable "image_uri_var" {
  description = "The Image URI from ECR"
  type        = string
  default     = "<account_id>.dkr.ecr.us-east-1.amazonaws.com/lambda-langchain:latest"
}