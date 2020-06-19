data "aws_availability_zones" "available_us-east" {
  provider = aws.aws-east-2
  state    = "available"
}

module "aws_east_vpc" {
  source  = "terraform-aws-modules/vpc/aws"

  name = var.aws_vpc_east_name
  cidr = var.aws_vpc_east_cidr_block

  azs  = [for zone in data.aws_availability_zones.available_us-east.names : zone]

  public_subnets = [for num in range(length(data.aws_availability_zones.available_us-east.names)) : cidrsubnet(var.aws_vpc_east_cidr_block, 5, (num + 1) * 8)]

  private_subnets = [for num in range(length(data.aws_availability_zones.available_us-east.names)) : cidrsubnet(var.aws_vpc_east_cidr_block, 5, ((num + 1) * 8) + 1)]

  enable_nat_gateway = true
  enable_vpn_gateway = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = var.aws_vpc_east_name
    Terraform   = "true"
    Environment = "dev"
  }

  providers = {
    aws = aws.aws-east-2
  }
}

data "aws_availability_zones" "available_us-west" {
  provider =  aws.aws-west-2
  state   = "available"
}

module "aws_west_vpc" {
  source  = "terraform-aws-modules/vpc/aws"

  name = var.aws_vpc_west_name
  cidr = var.aws_vpc_west_cidr_block

  # azs  = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]
  azs  = [for zone in data.aws_availability_zones.available_us-west.names : zone]

  public_subnets = [for num in range(length(data.aws_availability_zones.available_us-west.names)) : cidrsubnet(var.aws_vpc_west_cidr_block, 5, (num + 1) * 6)]

  private_subnets = [for num in range(length(data.aws_availability_zones.available_us-west.names)) : cidrsubnet(var.aws_vpc_west_cidr_block, 5, ((num + 1) * 6 ) + 1)]

  enable_nat_gateway = true
  enable_vpn_gateway = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = var.aws_vpc_west_name
    Terraform   = "true"
    Environment = "dev"
  }

  providers = {
    aws = aws.aws-west-2
  }
}

resource "aws_vpc_peering_connection" "peer" {
  provider      = aws.aws-east-2
  vpc_id        = module.aws_east_vpc.vpc_id
  peer_vpc_id   = module.aws_west_vpc.vpc_id
  peer_region   = "us-west-2"
  auto_accept   = false

  tags = {
    Name = "vpc-us-east-2 to vpc-us-west-2 VPC peering"
  }
}

resource "aws_vpc_peering_connection_accepter" "peer" {
  provider                  = aws.aws-west-2
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  auto_accept               = true
}

resource "aws_default_security_group" "us-east-vpc" {
  provider = aws.aws-east-2
  vpc_id   = module.aws_east_vpc.vpc_id

  ingress {
    protocol  = -1
    from_port = 0
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_default_security_group" "us-west-vpc" {
  provider = aws.aws-west-2
  vpc_id   = module.aws_west_vpc.vpc_id

  ingress {
    protocol  = -1
    from_port = 0
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

locals {
  admin_vpc_us_east_2_admin_vpc_routes    = setproduct(module.aws_east_vpc.public_route_table_ids, module.aws_west_vpc.public_subnets_cidr_blocks)
  admin_vpc_us_west_2_admin_vpc_routes    = setproduct(module.aws_west_vpc.public_route_table_ids, module.aws_east_vpc.public_subnets_cidr_blocks)
  admin_vpc_us_east_2_app_vpc_routes      = setproduct(module.aws_east_vpc.public_route_table_ids, module.aws_west_vpc.public_subnets_cidr_blocks)
  admin_vpc_us_west_2_app_vpc_routes      = setproduct(module.aws_west_vpc.public_route_table_ids, module.aws_east_vpc.public_subnets_cidr_blocks)
  app_vpc_us_east_2_app_vpc_routes        = setproduct(module.aws_east_vpc.public_route_table_ids, module.aws_west_vpc.public_subnets_cidr_blocks)
  app_vpc_us_west_2_app_vpc_routes        = setproduct(module.aws_west_vpc.public_route_table_ids, module.aws_east_vpc.public_subnets_cidr_blocks)
  app_vpc_us_east_2_admin_vpc_routes      = setproduct(module.aws_east_vpc.public_route_table_ids, module.aws_west_vpc.public_subnets_cidr_blocks)
  app_vpc_us_west_2_admin_vpc_routes      = setproduct(module.aws_west_vpc.public_route_table_ids, module.aws_east_vpc.public_subnets_cidr_blocks)
}

resource "aws_route" "admin_vpc_us_east_2_admin_vpc_route" {
  provider = aws.aws-east-2
  count    = length(local.admin_vpc_us_east_2_admin_vpc_routes)
  route_table_id            = local.admin_vpc_us_east_2_admin_vpc_routes[count.index][0]
  destination_cidr_block    = local.admin_vpc_us_east_2_admin_vpc_routes[count.index][1]
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}

resource "aws_route" "admin_vpc_eu_central_1_admin_vpc_route" {
  provider = aws.aws-west-2
  count    = length(local.admin_vpc_us_west_2_admin_vpc_routes)
  route_table_id            = local.admin_vpc_us_west_2_admin_vpc_routes[count.index][0]
  destination_cidr_block    = local.admin_vpc_us_west_2_admin_vpc_routes[count.index][1]
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}

# resource "aws_route" "us-vpc" {
#   provider                  = aws.aws-east-2
#   count                     = length(module.aws_west_vpc.public_subnets_cidr_blocks)
#   route_table_id            = module.aws_east_vpc.public_route_table_ids[0]
#   destination_cidr_block    = module.aws_west_vpc.public_subnets_cidr_blocks[count.index]
#   vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
# }

# resource "aws_route" "eu-vpc" {
#   provider                  = aws.aws-west-2
#   count                     = length(module.aws_east_vpc.public_subnets_cidr_blocks)
#   route_table_id            = module.aws_west_vpc.public_route_table_ids[0]
#   destination_cidr_block    = module.aws_east_vpc.public_subnets_cidr_blocks[count.index]
#   vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
# }

