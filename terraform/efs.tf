resource "aws_efs_file_system" "myefs" {
   creation_token = "myefs"
   performance_mode = "generalPurpose"
   throughput_mode = "bursting"
   encrypted = "true"
 tags = {
     Name = "EFS-ST"
   }
 }
resource "aws_efs_mount_target" "efs-a" {
   file_system_id  = aws_efs_file_system.myefs.id
   subnet_id = "subnet-7ed96405"
   security_groups = [aws_security_group.allow_tlss.id]
}
resource "aws_efs_mount_target" "efs-b" {
   file_system_id  = aws_efs_file_system.myefs.id
   subnet_id = "subnet-997b10d5"
   security_groups = [aws_security_group.allow_tlss.id]
}
resource "aws_efs_mount_target" "efs-c" {
   file_system_id  = aws_efs_file_system.myefs.id
   subnet_id = "subnet-abe7ddc3"
   security_groups = [aws_security_group.allow_tlss.id]
}