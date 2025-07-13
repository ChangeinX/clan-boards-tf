output "nat_instance_id" {
  value = aws_instance.this.id
}

output "nat_eip" {
  value = data.aws_eip.nat.public_ip
}
