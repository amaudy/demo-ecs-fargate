# Get current AWS account ID and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}

# Create IAM role for Datadog
resource "aws_iam_role" "datadog_integration" {
  name = "DatadogAWSIntegrationRole-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::464622532012:root" # Datadog's AWS account
        }
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.datadog_external_id
          }
        }
      }
    ]
  })

  tags = var.tags
}

# Create IAM policy for Datadog
resource "aws_iam_role_policy" "datadog_integration" {
  name = "DatadogAWSIntegrationPolicy-${var.environment}"
  role = aws_iam_role.datadog_integration.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          var.alb_logs_bucket_arn,
          "${var.alb_logs_bucket_arn}/*"
        ]
      },
      {
        Action = [
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:GetMetricData",
          "cloudwatch:DescribeAlarms"
        ]
        Effect = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents"
        ]
        Effect = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "tag:GetResources",
          "apigateway:GET",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeLaunchConfigurations",
          "cloudfront:ListDistributions",
          "cloudtrail:DescribeTrails",
          "cloudtrail:GetTrailStatus",
          "directconnect:DescribeConnections",
          "directconnect:DescribeDirectConnectGatewayAssociations",
          "directconnect:DescribeDirectConnectGateways",
          "directconnect:DescribeVirtualInterfaces",
          "dynamodb:DescribeContinuousBackups",
          "dynamodb:DescribeTable",
          "dynamodb:DescribeTimeToLive",
          "dynamodb:ListExports",
          "dynamodb:ListTables",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeTags",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:DescribeInstanceHealth",
          "elasticloadbalancing:DescribeLoadBalancerPolicies",
          "elasticloadbalancing:DescribeTrustStores",
          "ecs:ListClusters",
          "ecs:ListContainerInstances",
          "ecs:DescribeContainerInstances",
          "ecs:ListServices",
          "ecs:DescribeServices",
          "ecs:DescribeTasks",
          "ecs:ListTasks",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeCapacityProviders",
          "ecs:DescribeClusters"
        ]
        Effect = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "ec2:DescribeAddresses",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeCapacityReservationFleets",
          "ec2:DescribeCapacityReservations",
          "ec2:DescribeCarrierGateways",
          "ec2:DescribeClientVpnEndpoints",
          "ec2:DescribeCoipPools",
          "ec2:DescribeCustomerGateways",
          "ec2:DescribeDhcpOptions",
          "ec2:DescribeEgressOnlyInternetGateways",
          "ec2:DescribeFleets",
          "ec2:DescribeFlowLogs",
          "ec2:DescribeHostReservations",
          "ec2:DescribeHosts",
          "ec2:DescribeImages",
          "ec2:DescribeInstanceConnectEndpoints",
          "ec2:DescribeInstanceEventWindows",
          "ec2:DescribeInstances",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeIpamPools",
          "ec2:DescribeIpamResourceDiscoveries",
          "ec2:DescribeIpamResourceDiscoveryAssociations",
          "ec2:DescribeIpams",
          "ec2:DescribeIpamScopes",
          "ec2:DescribeIpv6Pools",
          "ec2:DescribeKeyPairs",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:DescribeLocalGatewayRouteTables",
          "ec2:DescribeLocalGatewayRouteTableVirtualInterfaceGroupAssociations",
          "ec2:DescribeLocalGatewayRouteTableVpcAssociations",
          "ec2:DescribeLocalGateways",
          "ec2:DescribeLocalGatewayVirtualInterfaceGroups",
          "ec2:DescribeLocalGatewayVirtualInterfaces",
          "ec2:DescribeManagedPrefixLists",
          "ec2:DescribeNatGateways",
          "ec2:DescribeNetworkAcls",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribePlacementGroups",
          "ec2:DescribeRegions",
          "ec2:DescribeReservedInstances",
          "ec2:DescribeRouteTables",
          "ec2:DescribeSecurityGroupRules",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSnapshotAttribute",
          "ec2:DescribeSnapshots",
          "ec2:DescribeSpotFleetRequests",
          "ec2:DescribeSpotInstanceRequests",
          "ec2:DescribeSubnets",
          "ec2:DescribeTrafficMirrorFilterRules",
          "ec2:DescribeTrafficMirrorFilters",
          "ec2:DescribeTrafficMirrorSessions",
          "ec2:DescribeTrafficMirrorTargets",
          "ec2:DescribeTransitGatewayAttachments",
          "ec2:DescribeTransitGatewayConnectPeers",
          "ec2:DescribeTransitGatewayMulticastDomains",
          "ec2:DescribeTransitGatewayPeeringAttachments",
          "ec2:DescribeTransitGatewayPolicyTables",
          "ec2:DescribeTransitGatewayRouteTableAnnouncements",
          "ec2:DescribeTransitGatewayRouteTables",
          "ec2:DescribeTransitGateways",
          "ec2:DescribeTransitGatewayVpcAttachments",
          "ec2:DescribeVerifiedAccessEndpoints",
          "ec2:DescribeVerifiedAccessGroups",
          "ec2:DescribeVerifiedAccessInstances",
          "ec2:DescribeVerifiedAccessTrustProviders",
          "ec2:DescribeVolumes",
          "ec2:DescribeVpcBlockPublicAccessExclusions",
          "ec2:DescribeVpcBlockPublicAccessOptions",
          "ec2:DescribeVpcEndpointConnectionNotifications",
          "ec2:DescribeVpcEndpoints",
          "ec2:DescribeVpcEndpointServicePermissions",
          "ec2:DescribeVpcEndpointServices",
          "ec2:DescribeVpcPeeringConnections",
          "ec2:DescribeVpcs",
          "ec2:DescribeVpnConnections",
          "ec2:DescribeVpnGateways",
          "ec2:GetTransitGatewayPrefixListReferences",
          "ec2:SearchTransitGatewayRoutes"
        ]
        Effect = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "elasticache:DescribeCacheClusters",
          "elasticache:DescribeCacheParameterGroups",
          "elasticache:DescribeCacheSecurityGroups",
          "elasticache:DescribeCacheSubnetGroups",
          "elasticache:DescribeReplicationGroups",
          "elasticache:DescribeReservedCacheNodes",
          "elasticache:DescribeSnapshots",
          "elasticache:DescribeUserGroups",
          "elasticache:DescribeUsers",
          "elasticfilesystem:DescribeAccessPoints",
          "elasticfilesystem:DescribeFileSystems",
          "elasticmapreduce:DescribeCluster",
          "elasticmapreduce:DescribeSecurityConfiguration",
          "elasticmapreduce:ListClusters",
          "elasticmapreduce:ListInstances",
          "elasticmapreduce:ListSecurityConfigurations",
          "es:ListDomainNames",
          "fsx:DescribeFileSystems",
          "kinesis:ListStreams",
          "lambda:GetPolicy",
          "lambda:ListCodeSigningConfigs",
          "lambda:ListFunctions",
          "lambda:ListLayers"
        ]
        Effect = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "rds:DescribeDBClusterParameterGroups",
          "rds:DescribeDBClusters",
          "rds:DescribeDBClusterSnapshotAttributes",
          "rds:DescribeDBClusterSnapshots",
          "rds:DescribeDBInstanceAutomatedBackups",
          "rds:DescribeDBInstances",
          "rds:DescribeDBParameterGroups",
          "rds:DescribeDBSecurityGroups",
          "rds:DescribeDBSnapshotAttributes",
          "rds:DescribeDBSnapshots",
          "rds:DescribeDBSubnetGroups",
          "rds:DescribeEventSubscriptions",
          "rds:DescribeExportTasks",
          "rds:DescribeOptionGroups",
          "rds:DescribeReservedDBInstances",
          "redshift:DescribeClusters",
          "redshift:DescribeLoggingStatus",
          "route53:ListHostedZones",
          "route53:ListQueryLoggingConfigs",
          "s3:ListAllMyBuckets",
          "ses:GetIdentityDkimAttributes",
          "ses:GetIdentityMailFromDomainAttributes",
          "ses:GetIdentityVerificationAttributes",
          "states:ListStateMachines"
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}
