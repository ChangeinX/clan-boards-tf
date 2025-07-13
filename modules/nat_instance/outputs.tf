output "nat_instance_id" {
  value = aws_instance.this.id
}

output "nat_eip" {
  value = aws_eip.nat.public_ip
}

output "nat_eip_allocation_id" {
  value = aws_eip.nat.id
}
