output "base_domain_nameservers" {  
  value = "${module.dnsModule.domain_name_servers}"
}module "networkModule" {
    source			= "./modules/network"
 	access_key		= "${var.access_key}"
	secret_key		= "${var.secret_key}"
	region			= "${var.region}"
	environment_tag = "${var.environment_tag}"
}

module "securityGroupModule" {
    source			= "./modules/securityGroup"
 	access_key		= "${var.access_key}"
	secret_key		= "${var.secret_key}"
	region			= "${var.region}"
	vpc_id			= "${module.networkModule.vpc_id}"
	environment_tag = "${var.environment_tag}"
}

module "instanceModule" {
	source 				= "./modules/instance"
	access_key 			= "${var.access_key}"
 	secret_key 			= "${var.secret_key}"
 	region     			= "${var.region}"
 	vpc_id 				= "${module.networkModule.vpc_id}"
	subnet_public_id	="${module.networkModule.public_subnets[0]}"
	key_pair_name		="${module.networkModule.ec2keyName}"
	security_group_ids 	= ["${module.securityGroupModule.sg_22}", "${module.securityGroupModule.sg_80}"]
	environment_tag 	= "${var.environment_tag}"
}

module "dnsModule" {
	source 		= "./modules/dns"
 	access_key 	= "${var.access_key}"
	secret_key 	= "${var.secret_key}"
	region     	= "${var.region}"
	domain_name	= "miteshsharma.com"
	aRecords	= [
		"miteshsharma.com ${module.instanceModule.instance_eip}",
	]
	cnameRecords	= [
		"www.miteshsharma.com miteshsharma.com"
	]
}variable "access_key" { }
variable "secret_key" { }
variable "region" {
  default = "us-east-2"
}
variable "availability_zone" {
  default = "us-east-2a"
}
variable "environment_tag" {
  description = "Environment tag"
  default = "dev"
}output "vpc_id" {
  value = "${aws_vpc.vpc.id}"
}
output "public_subnets" {
  value = ["${aws_subnet.subnet_public.id}"]
}
output "ec2keyName" {
  value = "${aws_key_pair.ec2key.key_name}"
}provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

#resources
resource "aws_vpc" "vpc" {
  cidr_block = "${var.cidr_block_range}"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags {
    "Environment" = "${var.environment_tag}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags {
    "Environment" = "${var.environment_tag}"
  }
}

resource "aws_subnet" "subnet_public" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "${var.subnet1_cidr_block_range}"
  map_public_ip_on_launch = "true"
  availability_zone = "${var.availability_zone}"
  tags {
    "Environment" = "${var.environment_tag}"
    "Type" = "Public"
  }
}

resource "aws_route_table" "rtb_public" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = "${aws_internet_gateway.igw.id}"
  }

  tags {
    "Environment" = "${var.environment_tag}"
  }
}

resource "aws_route_table_association" "rta_subnet_public" {
  subnet_id      = "${aws_subnet.subnet_public.id}"
  route_table_id = "${aws_route_table.rtb_public.id}"
}

resource "aws_key_pair" "ec2key" {
  key_name = "publicKey"
  public_key = "${file(var.public_key_path)}"
}# Variables

variable "access_key" {}
variable "secret_key" {}
variable "region" {
  default = "us-east-2"
}
variable "availability_zone" {
  default = "us-east-2a"
}
variable "cidr_block_range" {
  description = "The CIDR block for the VPC"
  default = "10.1.0.0/16"
}
variable "subnet1_cidr_block_range" {
  description = "The CIDR block for public subnet of VPC"
  default = "10.1.0.0/24"
}
variable "subnet2_cidr_block_range" {
  description = "The CIDR block for private subnet of VPC"
  default = "10.2.0.0/24"
}
variable "environment_tag" {
  description = "Environment tag"
  default = ""
}
variable "public_key_path" {
  description = "Public key path"
  default = "~/.ssh/id_rsa.pub"
}output "instance_eip" {
  value = "${aws_eip.testInstanceEip.public_ip}"
}provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

resource "aws_instance" "instance" {
  ami           = "${var.instance_ami}"
  instance_type = "${var.instance_type}"
  subnet_id = "${var.subnet_public_id}"
  vpc_security_group_ids = ["${var.security_group_ids}"]
  key_name = "${var.key_pair_name}"

  tags {
		"Environment" = "${var.environment_tag}"
	}
}

resource "aws_eip" "testInstanceEip" {
  vpc       = true
  instance  = "${aws_instance.instance.id}"

  tags {
    "Environment" = "${var.environment_tag}"
  }
}# Variables

variable "access_key" {}
variable "secret_key" {}
variable "region" {
  default = "us-east-2"
}
variable "vpc_id" {
  description = "VPC id"
  default = ""
}
variable "subnet_public_id" {
  description = "VPC public subnet id"
  default = ""
}
variable "security_group_ids" {
  description = "EC2 ssh security group"
  type = "list"
  default = []
}
variable "environment_tag" {
  description = "Environment tag"
  default = ""
}
variable "key_pair_name" {
  description = "EC2 Key pair name"
  default = ""
}
variable "instance_ami" {
  description = "EC2 instance ami"
  default = "ami-0cf31d971a3ca20d6"
}
variable "instance_type" {
  description = "EC2 instance type"
  default = "t2.micro"
}output "sg_22" {
  value = "${aws_security_group.sg_22.id}"
}

output "sg_80" {
  value = "${aws_security_group.sg_80.id}"
}provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

resource "aws_security_group" "sg_22" {
  name = "sg_22"
  vpc_id = "${var.vpc_id}"

  # SSH access from the VPC
  ingress {
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

  tags {
    "Environment" = "${var.environment_tag}"
  }
}

resource "aws_security_group" "sg_80" {
  name = "sg_80"
  vpc_id = "${var.vpc_id}"

  ingress {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    "Environment" = "${var.environment_tag}"
  }
}variable "access_key" {}
variable "secret_key" {}
variable "region" {
  default = "us-east-2"
}

variable "vpc_id" {
  description = "VPC id"
  default = ""
}
variable "environment_tag" {
  description = "Environment tag"
  default = ""
}output "domain_name_servers" {  
  value = "${aws_route53_zone.domain.name_servers}"
}provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

#resources
resource "aws_route53_zone" "domain" {
  name = "${var.domain_name}"
  tags {
    "Environment" = "${var.environment_tag}"
  }
}

resource "aws_route53_record" "a_record_item" {
  zone_id = "${aws_route53_zone.domain.zone_id}"
  name    = "${element(split(" ", var.aRecords[count.index]),0)}"
  type    = "A"
  ttl     = "${var.ttl}"
  records = ["${element(split(" ", var.aRecords[count.index]),1)}"]
  count   = "${length(var.cnameRecords)}"
}

resource "aws_route53_record" "cname_record_item" {
  zone_id = "${aws_route53_zone.domain.zone_id}"
  name    = "${element(split(" ", var.cnameRecords[count.index]),0)}"
  type    = "CNAME"
  ttl     = "${var.ttl}"
  records = ["${element(split(" ", var.cnameRecords[count.index]),1)}"]
  count   = "${length(var.cnameRecords)}"
}# Variables
variable "access_key" {}
variable "secret_key" {}
variable "region" {
  default = "us-east-2"
}
variable "domain_name" {
  description = "Domain name"
  default = ""
}
variable "aRecords" {
  type = "list"
  default = []
}
variable "cnameRecords" {
  type = "list"
  default = []
}
variable "ttl" {
  description = "time to live"
  default = 300
}
variable "environment_tag" {
  description = "Environment tag"
  default = ""
}