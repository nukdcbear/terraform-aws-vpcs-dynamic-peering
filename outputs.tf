output "aws-availability-zones-east" {
  value = data.aws_availability_zones.available_us-east
}

output "aws-availability-zones-west" {
  value = data.aws_availability_zones.available_us-west
}

output "vpc-east-id" {
  value = module.aws_east_vpc.vpc_id
}

output "east-private-subnets" {
  value = module.aws_east_vpc.private_subnets
}

output "east-public-subnets" {
  value = module.aws_east_vpc.public_subnets
}

output "vpc-west-id" {
  value = module.aws_west_vpc.vpc_id
}

output "west-private-subnets" {
  value = module.aws_west_vpc.private_subnets
}

output "west-public-subnets" {
  value = module.aws_west_vpc.public_subnets
}