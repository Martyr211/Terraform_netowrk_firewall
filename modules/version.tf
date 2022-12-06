##### Author #####
# Name: Ayush Gupta
# Contact: ayush881gupta@gmail.com
##################

terraform {
  required_version = ">=1.0.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.31.0"
    }
  }
}