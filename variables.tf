variable "region" {
  description = "AWS region"
  default     = "ap-northeast-2"
}

variable "kinesis_firehose_stream_name" {
  description = "Name to be use on kinesis firehose stream"
}

variable "kinesis_firehose_stream_backup_prefix" {
  description = "The prefix name to use for the kinesis backup"
  default     = "backup"
}

variable "bucket_name" {
  description = "The bucket name"
}

variable "glue_catalog_database_name" {
  description = "The Glue catalog database name"
}

variable "glue_catalog_table_name" {
  description = "The Glue catalog database table name"
}

variable "glue_catalog_table_columns" {
  description = "A list of table columns"
  type        = "list"
}
