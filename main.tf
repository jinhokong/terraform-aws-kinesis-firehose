data "aws_region" "default" {}

resource "aws_kinesis_firehose_delivery_stream" "kinesis_firehose_stream" {
  name        = "${var.kinesis_firehose_stream_name}"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn       = "${aws_iam_role.kinesis_firehose_stream_role.arn}"
    bucket_arn     = "${aws_s3_bucket.kinesis_firehose_stream_bucket.arn}"
    buffer_size    = 128
    s3_backup_mode = "Enabled"

    s3_backup_configuration {
      role_arn   = "${aws_iam_role.kinesis_firehose_stream_role.arn}"
      bucket_arn = "${aws_s3_bucket.kinesis_firehose_stream_bucket.arn}"
      prefix     = "${var.kinesis_firehose_stream_backup_prefix}"

      cloudwatch_logging_options {
        enabled         = true
        log_group_name  = "${aws_cloudwatch_log_group.kinesis_firehose_stream_logging_group.name}"
        log_stream_name = "${aws_cloudwatch_log_stream.kinesis_firehose_stream_logging_stream.name}"
      }
    }

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = "${aws_cloudwatch_log_group.kinesis_firehose_stream_logging_group.name}"
      log_stream_name = "${aws_cloudwatch_log_stream.kinesis_firehose_stream_logging_stream.name}"
    }

    data_format_conversion_configuration {
      input_format_configuration {
        deserializer {
          hive_json_ser_de {}
        }
      }

      output_format_configuration {
        serializer {
          parquet_ser_de {}
        }
      }

      schema_configuration {
        database_name = "${aws_glue_catalog_database.glue_catalog_database.name}"
        table_name    = "${aws_glue_catalog_table.glue_catalog_table.name}"
        role_arn      = "${aws_iam_role.kinesis_firehose_stream_role.arn}"
      }
    }
  }
}

resource "aws_cloudwatch_log_group" "kinesis_firehose_stream_logging_group" {
  name = "/aws/kinesisfirehose/${var.kinesis_firehose_stream_name}"
}

resource "aws_cloudwatch_log_stream" "kinesis_firehose_stream_logging_stream" {
  log_group_name = "${aws_cloudwatch_log_group.kinesis_firehose_stream_logging_group.name}"
  name           = "S3Delivery"
}

resource "aws_s3_bucket" "kinesis_firehose_stream_bucket" {
  bucket = "${var.bucket_name}"
  acl    = "private"
}

resource "aws_glue_catalog_database" "glue_catalog_database" {
  name = "${var.glue_catalog_database_name}"
}

resource "aws_glue_catalog_table" "glue_catalog_table" {
  name          = "${var.glue_catalog_table_name}"
  database_name = "${aws_glue_catalog_database.glue_catalog_database.name}"

  parameters = {
    "classification" = "parquet"
  }

  storage_descriptor = {
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"
    location      = "s3://${aws_s3_bucket.kinesis_firehose_stream_bucket.bucket}/"

    ser_de_info = {
      name                  = "JsonSerDe"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"

      parameters = {
        "serialization.format" = 1
        "explicit.null"        = false
        "parquet.compression"  = "SNAPPY"
      }
    }

    columns = "${var.glue_catalog_table_columns}"
  }
}
