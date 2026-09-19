# AWS Auto-Healing Web Tier

This project deploys a highly available and self-healing web tier on AWS using Terraform.

The solution runs NGINX across two EC2 instances managed by an Auto Scaling Group and distributes incoming HTTP traffic through an Application Load Balancer.

If an instance is terminated or becomes unhealthy, the Auto Scaling Group automatically launches a replacement.

## Architecture

```mermaid
flowchart TD
    User[Internet / User] --> ALB[Application Load Balancer]

    ALB --> TG[Target Group]

    TG --> EC2A[EC2 - NGINX<br/>Availability Zone 2a]
    TG --> EC2B[EC2 - NGINX<br/>Availability Zone 2b]

    ASG[Auto Scaling Group<br/>Min: 2 / Desired: 2 / Max: 3] --> EC2A
    ASG --> EC2B

    LT[Launch Template<br/>Amazon Linux 2023<br/>NGINX User Data] --> ASG

    EC2A --> SUB1[Public Subnet 1]
    EC2B --> SUB2[Public Subnet 2]

    SUB1 --> VPC[VPC 10.0.0.0/16]
    SUB2 --> VPC

    VPC --> IGW[Internet Gateway]
```

## Architecture Flow

The Application Load Balancer is the public entry point for the application. HTTP traffic is forwarded to healthy EC2 instances registered with the target group.

The Auto Scaling Group maintains a desired capacity of two EC2 instances across two Availability Zones. If an instance is terminated or becomes unhealthy, the Auto Scaling Group launches a replacement using the Launch Template.

Each EC2 instance is automatically configured using user data, which installs and starts NGINX.

The EC2 security group accepts HTTP traffic only from the Application Load Balancer security group, rather than allowing direct HTTP access from the internet.

The overall traffic flow is:

```text
Internet
    |
    v
Application Load Balancer
    |
    v
Target Group
   / \
  v   v
EC2   EC2
2a    2b
```

## Why AWS?

AWS was selected for this assessment because I have an existing foundation in AWS from completing the AWS re/Start program.

This made AWS a natural choice for demonstrating the solution while also building further hands-on experience with AWS infrastructure and Terraform.

AWS provides the services required for the architecture, including EC2, Application Load Balancing, Auto Scaling, VPC networking and health monitoring.

## Key Components

- **VPC** – Provides the network boundary for the infrastructure.

- **Public Subnets** – Two subnets across `ap-southeast-2a` and `ap-southeast-2b` provide multi-AZ availability.

- **Internet Gateway and Route Table** – Provide internet connectivity for resources in the public subnets.

- **Application Load Balancer (ALB)** – Provides a single public endpoint and distributes HTTP traffic across healthy EC2 instances.

- **Listener** – Listens for HTTP traffic on port 80 and forwards requests to the target group.

- **Target Group** – Contains the backend EC2 instances and performs HTTP health checks on `/`.

- **Security Groups** – The ALB accepts HTTP traffic from the internet, while the EC2 instances accept HTTP traffic on port 80 only from the ALB security group.

- **Launch Template** – Defines how EC2 instances are created, including the Amazon Linux 2023 AMI, instance type, security group and user data.

- **User Data** – Automatically installs, enables and starts NGINX whenever a new EC2 instance is launched.

- **Auto Scaling Group (ASG)** – Maintains the required EC2 capacity and automatically launches replacement instances when necessary.

- **AWS Systems Manager Parameter Store** – Used to retrieve the Amazon Linux 2023 AMI rather than hard-coding a specific AMI ID.

- **Terraform Variables** – Make settings such as AWS region, Availability Zones, instance type and Auto Scaling capacity configurable.

- **Terraform Output** – Returns the Application Load Balancer DNS name used to access the website.

## Design Decisions

### Multi-AZ Deployment

The web tier uses two Availability Zones:

```text
ap-southeast-2a
ap-southeast-2b
```

The Auto Scaling Group has the following capacity configuration:

```text
Minimum capacity: 2
Desired capacity: 2
Maximum capacity: 3
```

Maintaining two instances provides N+1 capacity so that the web tier does not depend on a single EC2 instance.

### Load Balancer as the Public Entry Point

Users access the application through a single Application Load Balancer DNS endpoint.

The individual EC2 instances do not need separate application URLs. The ALB distributes requests between healthy instances registered with the target group.

### Security

Separate security groups are used for the Application Load Balancer and EC2 instances.

The ALB security group allows inbound HTTP traffic on port 80 from the internet.

The EC2 security group allows inbound HTTP traffic on port 80 only from the ALB security group.

This creates the intended traffic path:

```text
Internet -> ALB -> EC2
```

### Public Subnets

For this assessment, the EC2 instances are deployed in public subnets to keep the architecture simple and avoid the additional cost of a NAT Gateway.

Although the instances are located in public subnets, their EC2 security group restricts inbound HTTP traffic to the Application Load Balancer security group.

For a production architecture, private subnets for application instances would normally be considered depending on the application and security requirements.

### Dynamic Amazon Linux AMI

The Amazon Linux 2023 AMI is retrieved using the AWS Systems Manager public parameter rather than hard-coding an AMI ID.

This reduces the need to manually maintain region-specific AMI IDs in the Terraform configuration.

## How Self-Healing Works

The Auto Scaling Group maintains a desired capacity of two EC2 instances.

If an instance is terminated or becomes unhealthy, the Auto Scaling Group launches a replacement using the Launch Template.

The replacement process is:

```text
Instance terminated / unhealthy
          |
          v
Auto Scaling Group detects the issue
          |
          v
Launch Template
          |
          v
New EC2 instance
          |
          v
User data installs and starts NGINX
          |
          v
Target Group health check
          |
          v
Instance becomes healthy
          |
          v
ALB can send traffic to the instance
```

While the replacement instance is being created and becoming healthy, the remaining healthy instance can continue receiving traffic through the Application Load Balancer.

During validation, one EC2 instance was manually terminated. The Auto Scaling Group automatically launched a replacement instance, and the replacement subsequently passed the target group's health checks.

## Terraform Files

The Terraform configuration is separated into files based on responsibility:

```text
.
├── main.tf
├── variables.tf
├── vpc.tf
├── security_groups.tf
├── alb.tf
├── launch_template.tf
├── autoscaling.tf
└── outputs.tf
```

- `main.tf` – Terraform and AWS provider configuration.
- `variables.tf` – Configurable values used by the infrastructure.
- `vpc.tf` – VPC, subnets, Internet Gateway and routing.
- `security_groups.tf` – ALB and EC2 security groups.
- `alb.tf` – Application Load Balancer, listener and target group.
- `launch_template.tf` – EC2 Launch Template, Amazon Linux AMI lookup and NGINX user data.
- `autoscaling.tf` – Auto Scaling Group configuration.
- `outputs.tf` – Application Load Balancer DNS output.

## Prerequisites

The following tools are required:

- Terraform
- AWS CLI
- Git
- An AWS account with appropriate permissions

AWS credentials should be configured locally before running Terraform.

The default deployment region for this project is:

```text
ap-southeast-2
```

## Deployment

Clone the repository and change into the project directory.

Initialize Terraform:

```bash
terraform init
```

Format the Terraform configuration:

```bash
terraform fmt
```

Validate the configuration:

```bash
terraform validate
```

Review the infrastructure Terraform intends to create:

```bash
terraform plan
```

Deploy the infrastructure:

```bash
terraform apply
```

Review the proposed changes and enter:

```text
yes
```

when prompted.

After a successful deployment, Terraform outputs the Application Load Balancer DNS name:

```text
alb_dns_name = "..."
```

The value can also be retrieved using:

```bash
terraform output -raw alb_dns_name
```

Open the ALB DNS name using HTTP in a web browser to view the NGINX welcome page.

## Validation

The deployed infrastructure was tested to verify availability, self-healing and Terraform idempotency.

### N+1 Capacity

After deployment, the Auto Scaling Group contained two healthy EC2 instances in separate Availability Zones.

```text
EC2 Instance 1 -> Healthy -> InService -> ap-southeast-2a
EC2 Instance 2 -> Healthy -> InService -> ap-southeast-2b
```

### Load Balancer Health

Both EC2 instances successfully passed the Application Load Balancer target group health checks.

```text
EC2 Instance 1 -> healthy
EC2 Instance 2 -> healthy
```

### Self-Healing Test

One EC2 instance was manually terminated to simulate the loss of a VM.

The Auto Scaling Group detected the capacity/health change and automatically launched a replacement instance.

The replacement instance:

1. Was created using the Launch Template.
2. Started Amazon Linux 2023.
3. Executed the user-data bootstrap script.
4. Installed and started NGINX.
5. Registered with the target group.
6. Passed the target group health checks.
7. Returned the Auto Scaling Group to two healthy instances.

The Auto Scaling activity history confirmed that a new instance was launched in response to the terminated instance.

### Terraform Idempotency

After the self-healing process completed, another Terraform plan was executed.

Terraform returned:

```text
No changes. Your infrastructure matches the configuration.
```

This demonstrates that the Terraform configuration remained aligned with the desired infrastructure state after the Auto Scaling Group replaced the terminated EC2 instance.

## Cost Considerations

This architecture was designed primarily to demonstrate the availability and self-healing requirements of the assessment.

The main chargeable resources are:

- Two EC2 instances
- Application Load Balancer
- EBS storage
- Public IPv4 addressing
- Load Balancer Capacity Unit (LCU) usage where applicable

Running the complete architecture continuously in the Sydney region is expected to exceed the assessment target of AUD 20 per month at standard on-demand pricing.

For this reason, the environment is intended to be short-lived for assessment and validation purposes and should be destroyed after testing.

A production deployment would require a separate cost review and optimisation based on workload requirements.

## Assumptions

- HTTP is sufficient for the assessment; HTTPS and certificates are outside the current scope.
- The default NGINX welcome page is sufficient to demonstrate the web tier.
- Two EC2 instances satisfy the required N+1 capacity for this assessment.
- EC2 instances are deployed in public subnets to simplify the assessment architecture and avoid NAT Gateway cost.
- The environment is intended for demonstration/testing rather than continuous production use.
- Terraform is the source of truth for infrastructure configuration.

## Cleanup

To prevent unnecessary AWS charges after testing, destroy the Terraform-managed infrastructure:

```bash
terraform destroy
```

Review the resources Terraform intends to remove and enter:

```text
yes
```

when prompted.

After completion, Terraform should report that the managed resources have been destroyed.

## Summary

This project demonstrates an AWS web tier that is:

- Provisioned entirely using Terraform.
- Distributed across two Availability Zones.
- Load balanced through an Application Load Balancer.
- Protected using separate ALB and EC2 security groups.
- Automatically configured with NGINX using EC2 user data.
- Maintained by an Auto Scaling Group.
- Able to automatically replace a terminated instance.
- Idempotent when Terraform is run again without configuration changes.