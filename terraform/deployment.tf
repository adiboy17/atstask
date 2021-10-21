resource "null_resource" "nullresource"  {
depends_on = [
      aws_cloudfront_distribution.webdistributions,
  ]
connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/sudha/Downloads/key1.pem")
    host     = aws_instance.myins.public_ip
  }
  provisioner "remote-exec" {
    inline = [
	"sudo git clone https://github.com/2sudhanhu/task2.git /var/www/html/"
    ]
  }
}
resource "null_resource" "website"  {
depends_on = [
     null_resource.nullresource,
  ]
	provisioner "local-exec" {
	    command = "start chrome ${aws_instance.myins.public_ip}/index.html"
  	}
}