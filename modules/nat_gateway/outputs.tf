output "nat_gateway_id" {
  value = aws_nat_gateway.this.id
}

output "nat_eip" {
  value = aws_eip.nat.public_ip
}

output "nat_eip_allocation_id" {
  value = aws_eip.nat.id
}
