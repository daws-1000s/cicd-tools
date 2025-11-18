module "jenkins" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "jenkins"

  instance_type          = "t3.small"
  vpc_security_group_ids = ["sg-0067ac1bfd8ab69ae"]
  subnet_id              = "subnet-081031787d53f4ea6"
  ami                    = "ami-0733cbac1dcca0be4"
  user_data              = file("jenkins.sh")

  tags = { Name = "jenkins" }

  root_block_device = {
    volume_size           = 50
    volume_type           = "gp3"
    delete_on_termination = true
  }
}

module "jenkins_agent" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "jenkins-agent"

  instance_type          = "t3.small"
  vpc_security_group_ids = ["sg-0067ac1bfd8ab69ae"]
  subnet_id              = "subnet-081031787d53f4ea6"
  ami                    = "ami-0733cbac1dcca0be4"
  user_data              = file("jenkins-agent.sh")

  tags = { Name = "jenkins-agent" }

  root_block_device = {
    volume_size           = 50
    volume_type           = "gp3"
    delete_on_termination = true
  }
}

# Route53 private zone records
data "aws_route53_zone" "expense" {
  name         = var.zone_name
  private_zone = true
}

module "records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "~> 2.0"

  zone_id = data.aws_route53_zone.expense.zone_id

  records = [
    {
      name    = "jenkins"
      type    = "A"
      ttl     = 60
      records = [module.jenkins.public_ip]
      allow_overwrite = true
    },
    {
      name    = "jenkins-agent"
      type    = "A"
      ttl     = 60
      records = [module.jenkins_agent.private_ip]
      allow_overwrite = true
    }
  ]
}