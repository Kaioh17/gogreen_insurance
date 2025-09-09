# GoGreen Insurance AWS Architecture Documentation

## Project Overview
This document outlines the AWS cloud architecture solution designed for GoGreen Insurance, a regional insurance company migrating from on-premises infrastructure to AWS to address performance, reliability, and scalability challenges.

## Business Requirements
- **Company**: GoGreen Insurance (California-based with offices in Europe and South America)
- **Application**: 3-tier CRM web application supporting sales users globally
- **Goal**: Paperless operations with document storage and format conversion
- **Growth**: 90% user base growth expected over 3 years

## Current On-Premises Challenges
- Performance and reliability issues
- Overprovisioned architecture
- Expensive scaling ($100,000+ per upgrade)
- Long procurement (20 days) and deployment (1 week) cycles
- Multiple upgrades required annually

## AWS Architecture Solution

### High-Level Design
The solution implements a highly available, multi-AZ architecture in `us-east-1` region with:
- **Web Tier**: Auto-scaling EC2 instances behind Application Load Balancer
- **Application Tier**: Auto-scaling EC2 instances in private subnets
- **Database Tier**: RDS MySQL with Multi-AZ deployment and read replicas
- **Storage**: S3 for document storage with lifecycle policies
- **Security**: IAM, VPC, Security Groups, and encryption

### Network Architecture

#### VPC Configuration
- **Region**: us-east-1
- **VPC**: Single VPC with public and private subnets
- **Availability Zones**: 2 AZs for high availability
- **Internet Gateway**: For public internet access
- **NAT Gateway**: For private subnet internet access

#### Subnet Design
- **Public Subnets**: Web tier instances and NAT Gateway
- **Private Subnets**: Application and database tiers
- **Security Groups**: Tier-specific access controls

### Tier-by-Tier Solution

#### Web Tier
- **Solution**: Auto Scaling Group with Application Load Balancer
- **Instances**: t3.medium (2 vCPU, 4GB RAM) - matches current capacity
- **Scaling**: Target 50-60% memory utilization
- **Monitoring**: CloudWatch alarms for 400 HTTP errors (>100/minute)
- **Tags**: Key=Name, Value=web-tier

#### Application Tier
- **Solution**: Auto Scaling Group in private subnets
- **Instances**: m5.xlarge (4 vCPU, 16GB RAM) - matches current capacity
- **Scaling**: Target 50-60% CPU/memory utilization
- **Internet Access**: Via NAT Gateway for patching
- **Monitoring**: CloudWatch alarms for CPU (>75%) and memory (>80%)
- **Tags**: Key=Name, Value=app-tier

#### Database Tier
- **Solution**: RDS MySQL Multi-AZ with read replica
- **Instance**: db.r5.2xlarge (8 vCPU, 64GB RAM)
- **Storage**: Provisioned IOPS SSD (21,000 IOPS)
- **High Availability**: Primary in AZ-1, standby in AZ-2
- **Read Replica**: In AZ-2 for read scaling

### Security Implementation

#### Identity and Access Management
- **User Groups**:
  - System Administrators (2 users)
  - Database Administrators (2 users)
  - Monitoring Group (4 users)
- **Authentication**: MFA required for administrators
- **Password Policy**: Complex passwords, 90-day rotation, no reuse

#### Data Protection
- **Encryption at Rest**: EBS volumes and RDS encrypted with KMS
- **Encryption in Transit**: HTTPS/TLS for all communications
- **S3 Encryption**: Server-side encryption with KMS

### Storage and Backup

#### S3 Configuration
- **Purpose**: Document and image storage
- **Retention**: 5 years with lifecycle policies
- **Access Patterns**: Frequent for 3 months, infrequent thereafter
- **Lifecycle**: Standard → IA → Glacier → Deep Archive

#### Backup Strategy
- **RDS**: Automated backups with 4-hour RPO
- **EBS**: Snapshot-based backups
- **S3**: Cross-region replication for critical data

### Monitoring and Alerting

#### CloudWatch Integration
- **Metrics**: CPU, memory, disk, network utilization
- **Custom Metrics**: Application-specific monitoring
- **Alarms**: Automated scaling and alert notifications

#### Notification System
- **SNS**: Email notifications for administrators
- **CloudTrail**: API logging and audit trail
- **S3**: Centralized log storage

### Cost Optimization

#### Managed Services
- **RDS**: Reduces database management overhead
- **S3**: Pay-per-use storage with lifecycle policies
- **Auto Scaling**: Right-size resources based on demand
- **Reserved Instances**: Cost savings for predictable workloads

#### Storage Optimization
- **S3 Lifecycle**: Automatic transition to cheaper storage classes
- **EBS Optimization**: Right-sized storage with appropriate IOPS

## Implementation Benefits

### Scalability
- **Auto Scaling**: Automatic capacity adjustment based on demand
- **Multi-AZ**: Built-in high availability
- **Read Replicas**: Database read scaling

### Reliability
- **99.99% Availability**: Multi-AZ deployment
- **Automated Failover**: RDS Multi-AZ and load balancer health checks
- **Backup and Recovery**: Comprehensive backup strategy

### Security
- **Defense in Depth**: Multiple security layers
- **Compliance**: Encryption and audit logging
- **Access Control**: Role-based permissions

### Cost Efficiency
- **Pay-per-use**: Only pay for resources consumed
- **Managed Services**: Reduced operational overhead
- **Lifecycle Policies**: Automatic cost optimization

## Next Steps
1. **Terraform Implementation**: Infrastructure as Code deployment
2. **Migration Planning**: Data migration from on-premises
3. **Testing**: Load testing and performance validation
4. **Monitoring Setup**: Comprehensive monitoring and alerting
5. **Documentation**: Operational runbooks and procedures

## Learning Outcomes
This project demonstrates:
- AWS service selection and configuration
- High availability and disaster recovery planning
- Security best practices implementation
- Cost optimization strategies
- Infrastructure as Code principles
- Multi-tier application architecture design
