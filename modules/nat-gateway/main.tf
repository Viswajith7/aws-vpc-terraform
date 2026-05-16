# ─────────────────────────────────────────────────────────────
#  modules/nat-gateway/main.tf
#  One EIP + one NAT GW per AZ → high-availability egress
# ─────────────────────────────────────────────────────────────

resource "aws_eip" "nat" {
  count  = length(var.availability_zones)
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-${var.environment}-nat-eip-${var.availability_zones[count.index]}"
  }
}

resource "aws_nat_gateway" "main" {
  count         = length(var.availability_zones)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = var.public_subnet_ids[count.index]

  depends_on = [aws_eip.nat]

  tags = {
    Name = "${var.project_name}-${var.environment}-nat-${var.availability_zones[count.index]}"
  }
}

# Add default route to each private route table pointing → NAT GW in same AZ
resource "aws_route" "private_nat" {
  count                  = length(var.availability_zones)
  route_table_id         = var.private_route_table_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[count.index].id
}
