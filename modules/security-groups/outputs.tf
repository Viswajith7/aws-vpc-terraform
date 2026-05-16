output "sg_web_id"     { value = aws_security_group.web.id }
output "sg_app_id"     { value = aws_security_group.app.id }
output "sg_db_id"      { value = aws_security_group.db.id }
output "sg_bastion_id" { value = aws_security_group.bastion.id }
