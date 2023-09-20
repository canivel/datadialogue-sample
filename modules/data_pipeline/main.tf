//S3

resource "aws_s3_bucket" "this" {
  bucket_prefix = "${var.prefix}"
}

locals {
  files = tolist(fileset("${path.cwd}/sample-datasets", "**/*"))
}

resource "aws_s3_object" "files" {
  count  = var.load_data && length(local.files) > 0 ? length(local.files) : 0
  bucket = aws_s3_bucket.this.bucket
  key    = local.files[count.index]
  source = "${path.cwd}/sample-datasets/${local.files[count.index]}"
  etag   = filemd5("${path.cwd}/sample-datasets/${local.files[count.index]}")
}

resource "aws_s3_bucket" "athena_results" {
  bucket_prefix = "${var.prefix}athena-results-"
}


//GLUE

resource "aws_glue_catalog_database" "this" {
  name = "data-dialogue-poc-database"
}

resource "aws_glue_crawler" "this" {
  name          = "data-dialogue-poc-crawler"
  database_name = aws_glue_catalog_database.this.name
  role          = aws_iam_role.glue_role.arn

  s3_target {
    path = "s3://${aws_s3_bucket.this.bucket}/"
  }

  provisioner "local-exec" {
    command = "aws glue start-crawler --name ${self.name}"
  }
}

resource "aws_iam_role" "glue_role" {
  name = "GlueServiceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "glue.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = ""
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "glue_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
  role       = aws_iam_role.glue_role.name
}

resource "aws_iam_policy" "s3_access" {
  name        = "S3AccessPolicy"
  description = "Data Dialogue Policy that grants access to S3"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        Resource = [
          "${aws_s3_bucket.this.arn}",
          "${aws_s3_bucket.this.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_access_attachment" {
  policy_arn = aws_iam_policy.s3_access.arn
  role       = aws_iam_role.glue_role.name
}