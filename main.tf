data "aws_vpc" "default" {
  default = true #To capture data about default VPC
}

data "aws_subnets" "all" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

module "firewall" {

  source = "./modules/"

  enabled                 = true
  create_network_firewall = true # Set to false if you just want to create the security policy, stateless and stateful rules

  name                              = "firewall-example"
  description                       = "AWS Network Firewall example"
  delete_protection                 = false
  firewall_policy_name              = "firewall-policy-example"
  firewall_policy_change_protection = false
  subnet_change_protection          = false


  # VPC
  vpc_id         = data.aws_vpc.default.id
  subnet_mapping = data.aws_subnets.all.ids

  # Stateless rule groups
  stateless_rule_groups = {
    stateless-group-1 = {
      description = "Stateless rules"
      priority    = 1
      capacity    = 100
      rules = [
        {
          priority  = 1
          actions   = ["aws:drop"]
          protocols = [6, 17]
          source = {
            address = "20.0.0.0/16"
          }
          source_port = {
            from_port = 23
            to_port   = 23
          }
          destination = {
            address = "30.0.0.0/16"
          }
          destination_port = {
            from_port = 23
            to_port   = 23
          }
        },
        {
          priority  = 3
          actions   = ["aws:pass"]
          protocols = [6, 17]
          source = {
            address = "1.1.3.4/32"
          }
          source_port = {
            from_port = 443
            to_port   = 443
          }
          destination = {
            address = "111.1.1.5/32"
          }
          destination_port = {
            from_port = 443
            to_port   = 443
          }
        },
        {
          priority = 10
          actions  = ["aws:forward_to_sfe"]
          source = {
            address = "0.0.0.0/0"
          }
          destination = {
            address = "0.0.0.0/0"
          }
        },
      ]
    }
  }


  # Stateful rules
  stateful_rule_groups = {
    # rules_source_list examples
    stateful-group-1 = {
      description = "Stateful Inspection for denying access to domains"
      capacity    = 100
      rules_source_list = {
        generated_rules_type = "DENYLIST"
        target_types         = ["TLS_SNI", "HTTP_HOST"]
        targets              = [".archive.org", ".badsite.com", ".inferno.com"]
      }
    }
    stateful-group-2 = {
      description = "Stateful Inspection for allowing access to domains"
      capacity    = 100
      rule_variables = {
        ip_sets = {
          HOME_NET     = ["10.0.0.0/16", "10.1.0.0/16", "192.0.2.0/24"]
          EXTERNAL_NET = ["20.0.0.0/16", "20.1.0.0/16", "192.0.3.0/24"]
          HTTP_SERVERS = ["10.2.0.0/24", "10.1.0.0/24"]
        }
        port_sets = {
          HTTP_PORTS = ["82", "8080"]
        }
      }
      rules_source_list = {
        generated_rules_type = "ALLOWLIST"
        target_types         = ["TLS_SNI", "HTTP_HOST"]
        targets              = [".wikipedia.org"]
      }
    }
    # stateful_rule examples
    stateful-group-3 = {
      description = "Permits http traffic from source"
      capacity    = 50
      stateful_rule = {
        action = "DROP"
        header = {
          destination      = "124.1.1.24/32"
          destination_port = 53
          direction        = "ANY"
          protocol         = "TCP"
          source           = "1.2.3.4/32"
          source_port      = 53
        }
        rule_option = {
          keyword = "sid:1"
        }
      }
    }

  }

  # Stateful Managed Rules
  stateful_managed_rule_groups_arn = [
    {
      resource_arn = "arn:aws:network-firewall:ap-south-1:aws-managed:stateful-rulegroup/AbusedLegitMalwareDomainsActionOrder"
    },
    {
      resource_arn = "arn:aws:network-firewall:ap-south-1:aws-managed:stateful-rulegroup/ThreatSignaturesBotnetActionOrder"
    }
  ]

  tags = local.tags
}
