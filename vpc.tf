# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE A VPC
# This Terraform template creates a full VPC. The VPC includes 2 types of subnets:
# - Public (one per AZ)
# - Private (one per AZ)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ---------------------------------------------------------------------------------------------------------------------
# CREATE VPC AND INTERNET GATEWAY
# ---------------------------------------------------------------------------------------------------------------------

# Create the VPC
resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  instance_tenancy     = var.instance_tenancy
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(
    {
      Name = local.prefix
    },
    var.custom_tags,
    var.vpc_custom_tags,
  )
}

# Create an Internet Gateway for our VPC
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = merge(
    {
      "Name" = format("%s", local.prefix)
    },
    var.custom_tags,
  )
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE PUBLIC SUBNETS
# Any resource that must be addressable from the public Internet should be placed in a Public Subnet.  E.g. ELB's, web
# servers, etc.
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_subnet" "public" {
  count = length(var.public_subnets) > 0 || length(var.public_subnets) >= length(var.azs) ? length(var.public_subnets) : 0

  vpc_id                  = aws_vpc.this.id
  cidr_block              = element(concat(var.public_subnets, [""]), count.index)
  availability_zone       = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null
  #availability_zone_id    = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) == 0 ? element(var.azs, count.index) : null
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(
    {
      "Name" = format("%s-public-%s", local.prefix, element(var.azs, count.index))
    },
    var.custom_tags,
    var.public_subnet_custom_tags,
  )
}

# Create a Route Table for public subnets
# - This routes all public traffic through the Internet gateway
# - All traffic to endpoints within the VPC is by default routed w/o going through the dirty Internet
resource "aws_route_table" "public" {

  vpc_id = aws_vpc.this.id

  tags = merge(
    {
      "Name" = format("%s-public", local.prefix)
    },
    var.custom_tags,
  )
}

# This route allows to have internet access. Routing traffic out throuh our internet gateway.
resource "aws_route" "internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id

  # Wait until internet_gateway and the route_table is created.
  depends_on = [
    aws_internet_gateway.this,
    aws_route_table.public,
  ]

  # https://github.com/terraform-providers/terraform-provider-aws/issues/338#issuecomment-379646260
  timeouts {
    create = "5m"
  }
}

# Associate each public subnet with a public route table
resource "aws_route_table_association" "public" {
  count = length(var.public_subnets) > 0 ? length(var.public_subnets) : 0

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ---------------------------------------------------------------------------------------------------------------------
# LAUNCH THE NAT GATEWAYS
# A NAT Gateway enables instances in the private subnet to connect to the Internet or other AWS services, but prevents
# the Internet from initiating a connection to those instances.
# ---------------------------------------------------------------------------------------------------------------------

# A NAT Gateway must be associated with an Elastic IP Address
resource "aws_eip" "nat" {
  vpc   = true
  tags = merge(
    {
      Name = "${local.prefix}-nat-gateway"
    },
    var.custom_tags,
  )
  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id = aws_subnet.public[0].id
  tags = merge(
    {
      Name = format("%s-%s-%s",local.prefix, "nat-gateway", aws_subnet.public[0].id)
    },
    var.custom_tags
  )

  depends_on = [aws_internet_gateway.this]
}

# -----------------------------------------------------------------------------------------------------------------------
# CREATE PRIVATE SUBNETS
# These subnets are private and meant to house any application/service that does not require direct connectivity from
# users.
# -----------------------------------------------------------------------------------------------------------------------

# Create private subnets
resource "aws_subnet" "private" {
  count = length(var.private_subnets) > 0 ? length(var.private_subnets) : 0

  vpc_id               = aws_vpc.this.id
  cidr_block           = var.private_subnets[count.index]
  availability_zone    = element(var.azs, count.index)
  #availability_zone_id = element(var.azs, count.index)

  tags = merge(
    {
      "Name" = format("%s-private-%s", local.prefix, element(var.azs, count.index))
    },
    var.custom_tags,
    var.private_subnet_custom_tags,
  )
}

# Create a Route Table for each private subnet
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  tags   = merge(
    {
      "Name" = "${local.prefix}-private"
    },
    var.custom_tags,
  )

  lifecycle {
    # When attaching VPN gateways it is common to define aws_vpn_gateway_route_propagation
    # resources that manipulate the attributes of the routing table (typically for the private subnets)
    ignore_changes = [propagating_vgws]
  }
}

# Create a route for outbound Internet traffic.
resource "aws_route" "private_nat_gateway" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id

  timeouts {
    create = "5m"
  }
}

# Associate each private subnet with its respective route table
resource "aws_route_table_association" "private" {
  count = length(var.private_subnets) > 0 ? length(var.private_subnets) : 0

  #subnet_id = element(aws_subnet.private.*.id, count.index)
  subnet_id = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}