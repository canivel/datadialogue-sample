# Provider and variable configurations
provider "aws" {
  region  = "us-east-1" # or any other region
  profile = var.aws_profile
}

# Data pipeline module (S3, Glue, etc.)
module "data_pipeline" {
  source = "./modules/data_pipeline"
  prefix    = var.prefix
  load_data = var.load_data
}

#API setup module (Lambda, API Gateway, Cognito)
module "api_setup" {
  source = "./modules/api_setup"
  athena_results_bucket_name = module.data_pipeline.athena_results_bucket_name
  glue_database_name             = module.data_pipeline.glue_database_name
}