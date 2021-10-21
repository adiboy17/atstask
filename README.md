# Python web application in a Cloud-based Kubernetes solution.

----------------------------------------------------------

## Writing an Infrastructure as code using Terraform:

1.  Configure the Provider: To do this step you need to have AWS-CLI signed in. To know more about how to do it please check how to launch ec2."
```terraform
provider "aws" {
   region  = "ap-south-1"
   profile = "govind"
}
```

2. Create Key Pair: Here we have used resource ‘tls_private_key’ to create private key saved locally with the name ‘webserver_key.pem’. Then to create ‘AWS Key Pair’ we used resource ‘aws_key_pair’ and used our private key here as public key.
```terraform
resource “tls_private_key” “webserver_private_key” {
 algorithm = “RSA”
 rsa_bits = 4096
}
resource “local_file” “private_key” {
 content = tls_private_key.webserver_private_key.private_key_pem
 filename = “webserver_key.pem”
 file_permission = 0400
}
resource “aws_key_pair” “webserver_key” {
 key_name = “webserver”
 public_key = tls_private_key.webserver_private_key.public_key_openssh
}
```
3. Create a Security Group: We want to access our website through HTTP protocol so need to set this rule while creating a Security group. Also, we want remote access of instances(OS) through ssh to configure it.
```terraform
resource "aws_security_group" "allow_http_ssh" {
  name        = "allow_http"
  description = "Allow http inbound traffic"
ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
 
  }
ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
   }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
tags = {
    Name = "allow_http_ssh"
  }
}
```
4. Launch EC2 instance: We want to deploy our website on EC2 instance so that we need to launch an instance with installed servers and other dependencies. for that, we create an instance and downloading https, PHP, git to configure it.
```terraform
resource "aws_instance" "webserver" {
  ami           = "ami-0447a12f28fddb066"
  instance_type = "t2.micro" 
  key_name  = aws_key_pair.webserver_key.key_name
  security_groups=[aws_security_group.allow_http_ssh.name]
tags = {
    Name = "webserver_task1"
  }
  connection {
        type    = "ssh"
        user    = "ec2-user"
        host    = aws_instance.webserver.public_ip
        port    = 22
        private_key = tls_private_key.webserver_private_key.private_key_pem
    }
        ]
    }
}
```
5. Create EBS Volume: Why we need EBS volume? We want to store code in persistent storage so that instance termination could not affect it.
```terraform
resource "aws_ebs_volume" "my_volume" {
    availability_zone = aws_instance.webserver.availability_zone
    size              = 1
    tags = {
        Name = "webserver-pd"
    }
}
```

6. Attach EBS volume to EC2 instance.
```terraform
resource "aws_volume_attachment" "ebs_attachment" {
    device_name = "/dev/xvdf"
    volume_id   =  aws_ebs_volume.my_volume.id
    instance_id = aws_instance.webserver.id
    force_detach =true     
   depends_on=[ aws_ebs_volume.my_volume,aws_ebs_volume.my_volume]
}
```

7. Now time to run/apply infrastructure.
```terraform
#initalise and download pulgins
$ terraform init
#check for errors
$ terraform validate
#build the infrastructure
$ terraform apply -auto-approve
#destroy the infrastructure
$ terraform destroy -auto-approve
```

## Get the application code: 
- Use git to clone the repository to your local machine:
```git
https://github.com/adiboy17/atstask.git
```
- Change to the app directory:
```git
cd /app
```
- There are only two files in this directory. If you look at the main.py file, you’ll see the application prints out a hello message.
```git
from flask import Flask
import subprocess as sp
app = Flask(__name__)

@app.route("/")
def hello():
    output = sp.getoutput('echo $ATC_USERNAME' \n 'echo $ATC_PASSWORD')
    print(output)

if __name__ == "__main__":
    app.run(host='0.0.0.0')
```
The requirements.txt file contains the list of packages needed by the main.py and will be used by pip to install the Flask library.

- Run locally: Manually run the installer and application using the following commands:
```git
pip install -r requirements.txt
python main.py
```
- This will start a development web server hosting your application, which you will be able to see by navigating to http://localhost:5000
- Create a Dockerfile: In the hello-python/app directory, create a file named Dockerfile with the following contents and save it.
```git
FROM python:3.7

RUN mkdir /app
WORKDIR /app
ADD . /app/
RUN pip install -r requirements.txt

EXPOSE 5000
CMD ["python", "/app/main.py"]
```
- This file is a set of instructions Docker will use to build the image. For this simple application, Docker is going to:

Get the official Python Base Image for version 3.7 from Docker Hub.
In the image, create a directory named app.
Set the working directory to that new app directory.
Copy the local directory’s contents to that new folder into the image.
Run the pip installer (just like we did earlier) to pull the requirements into the image.
Inform Docker the container listens on port 5000.
Configure the starting command to use when the container starts

- Create an image: At your command line or shell, in the hello-python/app directory, build the image with the following command:
```git
docker build -f Dockerfile -t hello-python:latest .
```
This will perform those seven steps listed above and create the image. To verify the image was created, run the following command:

```git
docker image ls
```

- Running in Docker: Before jumping into Kubernetes, let’s verify it works in Docker. RNow navigate to http://localhost:5001, and you should see the “Hello from Python!” message.

```git
docker run -p 5001:5000 hello-python
```

## Running in Kubernetes: You are finally ready to get the application running in Kubernetes. Because you have a web application, you will create a service and a deployment.

- First verify your kubectl is configured. At the command line, type the following:
```git
kubectl version
```
If you don’t see a reply with a Client and Server version, you’ll need to install and configure it.
Now you are working with Kubernetes! You can see the node by typing:

```git
kubectl get nodes
```
Create a file named deployment.yaml and add the following contents to it and then save it:
```git
apiVersion: v1
kind: Service
metadata:
  name: hello-python-service
spec:
  selector:
    app: hello-python
  ports:
  - protocol: "TCP"
    port: 6000
    targetPort: 5000
  type: LoadBalancer

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-python
spec:
  selector:
    matchLabels:
      app: hello-python
  replicas: 4
  template:
    metadata:
      labels:
        app: hello-python
    spec:
      containers:
      - name: hello-python
        image: hello-python:latest
        imagePullPolicy: Never
        ports:
        - containerPort: 5000
```

This YAML file is the instructions to Kubernetes for what you want running. It is telling Kubernetes the following:

You want a load-balanced service exposing port 6000
You want four instances of the hello-python container running
Use kubectl to send the YAML file to Kubernetes by running the following command:
```git
kubectl apply -f deployment.yaml
```
You can see the pods are running if you execute the following command:
```git
kubectl get pods
```
