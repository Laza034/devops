ERRAFORM POJECT DOCUMENTATION v1.0

TOOLS:

Terraform v1.1.0-dev
AWS terraform-provider-aws_v3.57.0_x5


REQUIREMENTS:

This task is aimed at demonstrating the ability to use configuration management tooling to declaratively manifest Infrastructure as Code (IAC) for a cloud solution.
Consider this scenario:
You are a working with a hot new startup that needs a solution for deploying their applications in the cloud. In these early stages, the company only requires a simple and cheap cloud solution that can be used to demo the product.
For this solution, they want to use the AWS Cloud Platform for their application demo infrastructure.

SOLUTION:

Infrastructure is based on AWS best practice principals following 5 pillars:

1- Operational excellence:

IAC using Terraform to automate provisioning and configuration tasks. Build control and configuration version control.
EC2 instances were bootstrapped with user_data.sh outsied of main.tf code for easy future editing.

2- Security:

All layers security provided using AWS security groups and rules for individual recurses and traffic in turn minimizing
risk of uncontrolled and unauthorized access.

3- Reliability:

Utilizing Load Balancing in conjunction with AWS auto-scaling group over different AZs to provide instance failover mechanism without impact 
to customer traffic. Instance health-check are performed by LB for quick failover or replacement by AWS auto-scaling group.

4- Performance efficiency:

Recurse type is selected for optimal performance of the application. This pillar has potential for improvement by utilizing serverless scripting for ex.

5- Cost optimization:

Cost savings were achieved by utilizing spot instances since application is not using any dynamic content and can be spawn as needed. 


TRAFFIC ROUTING:

HTTP ---> LOAD BALANCER ---> 8080: TARGET GROUP INSTANCES


AWS RESURCES USED IN PROJECT:

data.aws_availability_zones.all
data.aws_subnet_ids.all
data.aws_vpc.default
aws_autoscaling_group.devops
aws_launch_template.config
aws_lb.awsalb
aws_lb_listener.http
aws_lb_target_group.servers
aws_route53_record.www
aws_route53_zone.dopestartup
aws_security_group.alb
aws_security_group.servers
aws_security_group_rule.alb-traffic
aws_security_group_rule.alb-traffic80
aws_security_group_rule.egress-alb
aws_security_group_rule.egress-servers
aws_security_group_rule.ingress-from-servers
aws_security_group_rule.management
aws_security_group_rule.web-access

GRAPH picture attached in repo as graphviz.svg
