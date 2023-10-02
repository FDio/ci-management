#!/bin/bash

# Copyright (c) 2021 Cisco and/or its affiliates.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

echo "---> terraform_s3_docs_ship.sh"

set -exuo pipefail

cat >"/w/workspace/main.tf" <<'END_OF_TERRAFORM_SCRIPT'
provider "aws" {
  region                      = "us-east-1"
  profile                     = "default"
  s3_use_path_style           = false
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
}

locals {
  mime_types = {
    xml   = "application/xml",
    html  = "text/html",
    txt   = "text/plain",
    log   = "text/plain",
    css   = "text/css",
    md    = "text/markdown",
    rst   = "text/x-rst",
    csv   = "text/csv",
    svg   = "image/svg+xml",
    jpg   = "image/jpeg",
    png   = "image/png",
    gif   = "image/gif",
    js    = "application/javascript",
    pdf   = "application/pdf"
    json  = "application/json",
    otf   = "font/otf",
    ttf   = "font/ttf",
    woff  = "font/woff",
    woff2 = "font/woff2"
  }
}

variable "workspace_dir" {
  description = "Workspace base directory"
  type        = string
}

variable "file_match_pattern" {
  description = "File matching pattern"
  type        = string
  default     = "**/*"
}

variable "bucket" {
  description = "S3 bucket name"
  type        = string
}

variable "bucket_path" {
  description = "S3 bucket path to key"
  type        = string
}

resource "aws_s3_object" "object" {
  for_each = fileset(var.workspace_dir, var.file_match_pattern)

  bucket = var.bucket
  key    = "${var.bucket_path}${each.value}"
  source = "${var.workspace_dir}/${each.value}"

  cache_control = "no-store,max-age=0,s-maxage=0"
  etag          = filemd5("${var.workspace_dir}/${each.value}")
  content_type = lookup(
    local.mime_types,
    regex("\\.(?P<extension>[A-Za-z0-9]+)$", each.value).extension,
    "application/octet-stream"
  )
}
END_OF_TERRAFORM_SCRIPT
