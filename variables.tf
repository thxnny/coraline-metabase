# ---------------------------------------------------------------------------
# Deployment inputs (must / may be set per deploy)
# ---------------------------------------------------------------------------
variable "region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "ap-southeast-1"
}

variable "aws_profile" {
  description = "Named AWS CLI profile to use. Empty string uses the default credential chain."
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Fully-qualified hostname Metabase will be served on, e.g. metabase.example.com."
  type        = string
}

variable "az_count" {
  description = "Number of Availability Zones to spread subnets across."
  type        = number
  default     = 2
}

# ---------------------------------------------------------------------------
# Sizing / version knobs (the values worth tuning)
# ---------------------------------------------------------------------------
variable "metabase_image" {
  description = "Metabase container image (pin a version, do not use :latest)."
  type        = string
  default     = "metabase/metabase:v0.50.30"
}

variable "metabase_cpu" {
  description = "Fargate task CPU units (1024 = 1 vCPU)."
  type        = number
  default     = 1024
}

variable "metabase_memory" {
  description = "Fargate task memory in MiB (JVM — 2048 minimum, 4096 if boot is slow)."
  type        = number
  default     = 2048
}

variable "metabase_desired_count" {
  description = "Number of Metabase tasks to run."
  type        = number
  default     = 1
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "db_name" {
  description = "Name of the Metabase application database."
  type        = string
  default     = "metabase"
}

variable "db_username" {
  description = "Master username for the Metabase application database."
  type        = string
  default     = "metabase"
}
