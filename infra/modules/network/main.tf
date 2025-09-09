module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project}-${var.env}-vpc"
  cidr = "10.30.0.0/16"

  azs             = [ "${var.region}a", "${var.region}b" ]
  public_subnets  = [ "10.30.0.0/20",  "10.30.16.0/20" ]
  private_subnets = [ "10.30.32.0/20", "10.30.48.0/20" ]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true
}

// SG for ALB (public 80)
resource "aws_security_group" "alb" {
  name   = "${var.project}-${var.env}-alb-sg"
  vpc_id = module.vpc.vpc_id
  ingress { 
    from_port=80 
    to_port=80 
    protocol="tcp" 
    cidr_blocks=["0.0.0.0/0"] 
    }
  egress  { 
    from_port=0  
    to_port=0  
    protocol="-1"   
    cidr_blocks=["0.0.0.0/0"] 
    }
}


