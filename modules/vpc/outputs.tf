output "vpc_id" { value = aws_vpc.main.id }
output "vpc_cidr" { value = aws_vpc.main.cidr_block }
output "internet_gateway_id" { value = aws_internet_gateway.main.id }
output "s3_endpoint_id" { value = aws_vpc_endpoint.s3.id }
