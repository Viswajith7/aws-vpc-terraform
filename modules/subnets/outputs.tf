output "public_subnet_ids" { value = aws_subnet.public[*].id }
output "private_subnet_ids" { value = aws_subnet.private[*].id }
output "db_subnet_ids" { value = aws_subnet.db[*].id }
output "db_subnet_group_name" { value = aws_db_subnet_group.main.name }
output "private_route_table_ids" { value = aws_route_table.private[*].id }
output "db_route_table_ids" { value = aws_route_table.db[*].id }
