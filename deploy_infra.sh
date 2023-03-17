#!/bin/bash

set -e

source ./dev.env

terraform init

terraform apply -var-file="vars.tfvars"