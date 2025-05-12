resource "aws_security_group" "web_sg" {
  name_prefix = "web-sg-"
  description = "Allow HTTP and SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}




resource "aws_instance" "app_server" {
  ami                         = "ami-084568db4383264d4" # Ubuntu 22.04 in us-east-1
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  key_name                    = "deployer" 
  associate_public_ip_address = false # Elastic IP will be attached

  tags = {
    Name = "Boardgame-App-Server"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update
              sudo apt install -y openjdk-17-jdk git
              git clone https://github.com/DevOpsInstituteMumbai-wq/Automating-Secure-Deployment-of-Board-game-Listing-WebApp-on-AWS.git
              cd Automating-Secure-Deployment-of-Board-game-Listing-WebApp-on-AWS
              ./mvnw spring-boot:run
              EOF
}


# Lookup existing allocated Elastic IP
data "aws_eip" "static_eip" {
  public_ip = "34.226.133.53"
}

# Associate the existing EIP with the EC2 instance
resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.app_server.id
  allocation_id = data.aws_eip.static_eip.id
}



