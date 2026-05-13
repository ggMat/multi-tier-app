output "instance_id" { value = aws_instance.this.id }
output "network_interface_id" { value = aws_network_interface.this.id }
output "public_ip" { value = aws_instance.this.public_ip }
