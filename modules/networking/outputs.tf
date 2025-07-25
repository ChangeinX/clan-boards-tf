output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

output "private_subnet_ids" {
  value = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}
output "vpc_cidr" {
  value = aws_vpc.this.cidr_block
}

output "private_route_table_id" {
  value = aws_route_table.private.id
}

