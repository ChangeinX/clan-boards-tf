resource "aws_eip" "nat" {
  vpc  = true
  tags = { Name = "${var.app_name}-nat-eip" }
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = var.subnet_id
  tags = {
    Name = "${var.app_name}-nat-gw"
  }
}

resource "aws_route" "private_to_nat" {
  route_table_id         = var.private_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this.id
}
