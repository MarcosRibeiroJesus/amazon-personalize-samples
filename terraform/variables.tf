variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "magic-movie-machine"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "personalize_domain" {
  description = "Personalize domain type"
  type        = string
  default     = "VIDEO_ON_DEMAND"
}

variable "dataset_group_name" {
  description = "Name of the Personalize dataset group"
  type        = string
  default     = "personalize-video-on-demand-ds-group"
}

variable "s3_bucket_prefix" {
  description = "Prefix for S3 bucket name"
  type        = string
  default     = "mmm"
}

variable "kinesis_shard_count" {
  description = "Number of shards for Kinesis stream"
  type        = number
  default     = 1
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 60
}

variable "lambda_memory" {
  description = "Lambda function memory in MB"
  type        = number
  default     = 256
}
