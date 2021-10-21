# create ec2 instance
resource "aws_instance" "myins" {
  ami             = "ami-0732b62d310b80e97"
  instance_type   = "t2.micro"
  key_name        = "key1"
  security_groups = ["allow_tlss"]
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("C:/Users/sudha/Downloads/key1.pem")
    host        = aws_instance.myins.public_ip
  }
  provisioner "remote-exec" {
    inline = [
       "sudo yum install httpd git -y",
       "sudo systemctl restart httpd",
       "sudo systemctl enable httpd",
    ]
  }
  provisioner "remote-exec" {
    inline = [
       "sudo yum install httpd amazon-efs-utils -y",
       "sudo sleep 3m",
       "sudo mount -t efs '${aws_efs_file_system.myefs.id}':/ /var/www/html",
       "sudo su -c \"echo '${aws_efs_file_system.myefs.id}:/ /var/www/html nfs4 defaults,vers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport 0 0' >> /etc/fstab\"",
    ]
  }
  tags = {
    Name = "myinstance"
  }
}
output "InstancePIP" {  
  value = aws_instance.myins.public_ip
}
