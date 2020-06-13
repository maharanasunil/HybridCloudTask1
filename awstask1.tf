provider "aws" {
  region   = "ap-south-1"
  profile  = "maharanasunil"
}

//Creating Key-Pair

resource "aws_key_pair" "taskkey" {
  key_name   = "awstask1"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCMxVqrbfouYQzMtp9mhr/xbqC7HZVHOpisOomQfR3qZ4DoKFayQpqZ6vYzcmMfDIaZCBRsuf5awZhTw4ea78ZCXtDs5SA8QD+/cgoubYwpMgoHwPvYm5pFrSlo51jxDs7yRl6gPVH63bdpl7VdRlkyO5ZjCamEdswWQBRn7yLiRD5s1RjoeA1PbrhRZhYGR/vQyhvq0Is3Z6MYoBMsurOoX4iStct6RDzWHPTSx+t6YGWZc0pLyVYdKOkmwqvPcAuCvA3H9DdgvoPrHlymgNPpFKi5+ALaCtQ73xca3S2j3Q13oW2tlsk8i5UwCD73Ev74XfGbRLV+WNUBWhFGTn9b awstask1"
}

//Creating Security Group 

resource "aws_security_group" "MySecurity" {
  name        = "MySecurity"
  description = "Allow SSH AND HTTP for webhosting"


  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "MySecurity"
  }
}

//Creating variable for key

variable "key_name" {
  type= string
  default = "awstask1"
}

//Creating Instance

resource "aws_instance" "myins" {
  ami           = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  availability_zone = "ap-south-1a"
  key_name      = var.key_name
  security_groups = [ aws_security_group.firewall.name ]
    
    user_data = <<-EOF
                #! /bin/bash
                sudo yum install httpd -y
                sudo systemctl start httpd
                sudo systemctl enable httpd
                sudo yum install git -y
                mkfs.ext4 /dev/xvdf1
                mount /dev/xvdf1 /var/www/html
                
                git clone https://github.com/whoaks/aksfile
                cd aksfile
                cp index.html /var/www/html
 EOF

  tags = {
     Name = "myos"
  }
}

//Creating EBS Volume 

resource "aws_ebs_volume" "ebsvol" {
  availability_zone = aws_instance.myin.availability_zone
  size              = 1

  tags = {
    Name = "EbsTask1"
  }
}

//Attachment of EBS Volume to Instance 

resource "aws_volume_attachment" "ebs_att" {
 device_name = "/dev/sdf"
 volume_id = aws_ebs_volume.ebs.id
 instance_id = aws_instance.myin.id
}

//Creating S3 Bucket

resource "aws_s3_bucket" "" {
    bucket = "task1sunil"
    acl    = "public-read"

    tags = {
	Name    = "task1sunil"
	Environment = "Dev"
    }
    versioning {
	enabled =true
    }
}

//Creating Cloudfront

resource "aws_cloudfront_distribution" "mycf" {
    origin {
        domain_name = "maharanasunil.s3.amazonaws.com"
        origin_id = "S3-aks12341234" 


        custom_origin_config {
            http_port = 80
            https_port = 80
            origin_protocol_policy = "match-viewer"
            origin_ssl_protocols = ["TLSv1", "TLSv1.1", "TLSv1.2"] 
        }
    }
       
    enabled = true


    default_cache_behavior {
        allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
        cached_methods = ["GET", "HEAD"]
        target_origin_id = "S3-aks12341234"


        # Forward all query strings, cookies and headers
        forwarded_values {
            query_string = false
        
            cookies {
               forward = "none"
            }
        }
        viewer_protocol_policy = "allow-all"
        min_ttl = 0
        default_ttl = 3600
        max_ttl = 86400
    }
    # Restricts who is able to access this content
    restrictions {
        geo_restriction {
            # type of restriction, blacklist, whitelist or none
            restriction_type = "none"
        }
    }


    # SSL certificate for the service.
    viewer_certificate {
        cloudfront_default_certificate = true
    }
}