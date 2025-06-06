#!/bin/bash
# Script pour nettoyer les ressources AWS existantes

# Configurer la région
export AWS_REGION=${1:-ca-central-1}
shift 2>/dev/null || true

# Analyser les options
CLEANUP_COMPUTE=false
CLEANUP_NETWORK=false
CLEANUP_STORAGE=false
CLEANUP_OTHER=false
CLEANUP_ALL=true

# Si des options sont spécifiées, désactiver le nettoyage complet
if [ $# -gt 0 ]; then
  CLEANUP_ALL=false
  while [ $# -gt 0 ]; do
    case "$1" in
      --compute) CLEANUP_COMPUTE=true ;;
      --network) CLEANUP_NETWORK=true ;;
      --storage) CLEANUP_STORAGE=true ;;
      --other) CLEANUP_OTHER=true ;;
      *) echo "Option inconnue: $1" ;;
    esac
    shift
  done
fi

echo "Suppression des ressources AWS dans la région $AWS_REGION..."
echo "Mode de nettoyage: $([ "$CLEANUP_ALL" = true ] && echo "COMPLET" || echo "SÉLECTIF")"
[ "$CLEANUP_COMPUTE" = true ] && echo "- Ressources de calcul: OUI" || true
[ "$CLEANUP_NETWORK" = true ] && echo "- Ressources réseau: OUI" || true
[ "$CLEANUP_STORAGE" = true ] && echo "- Ressources de stockage: OUI" || true
[ "$CLEANUP_OTHER" = true ] && echo "- Autres ressources: OUI" || true

# Supprimer les clusters EKS
if [ "$CLEANUP_ALL" = true ] || [ "$CLEANUP_COMPUTE" = true ]; then
  echo "Nettoyage des clusters EKS..."
  for cluster in $(aws eks list-clusters --region $AWS_REGION --query 'clusters[]' --output text); do
    echo "Suppression du cluster EKS: $cluster"
    for nodegroup in $(aws eks list-nodegroups --region $AWS_REGION --cluster-name $cluster --query 'nodegroups[]' --output text); do
      echo "Suppression du nodegroup: $nodegroup du cluster: $cluster"
      aws eks delete-nodegroup --region $AWS_REGION --cluster-name $cluster --nodegroup-name $nodegroup --no-paginate
      echo "Attente de la suppression du nodegroup..."
      aws eks wait nodegroup-deleted --region $AWS_REGION --cluster-name $cluster --nodegroup-name $nodegroup
    done
    aws eks delete-cluster --region $AWS_REGION --name $cluster
    echo "Attente de la suppression du cluster..."
    aws eks wait cluster-deleted --region $AWS_REGION --name $cluster
  done
fi

# Supprimer les instances EC2
if [ "$CLEANUP_ALL" = true ] || [ "$CLEANUP_COMPUTE" = true ]; then
  echo "Nettoyage des instances EC2..."
  for instance in $(aws ec2 describe-instances --region $AWS_REGION --filters "Name=instance-state-name,Values=running,stopped" --query 'Reservations[].Instances[].InstanceId' --output text); do
    echo "Suppression de l'instance EC2: $instance"
    aws ec2 terminate-instances --region $AWS_REGION --instance-ids $instance
  done

  # Attendre que les instances soient terminées
  echo "Attente de la terminaison des instances..."
  aws ec2 wait instance-terminated --region $AWS_REGION --filters "Name=instance-state-name,Values=terminated"
fi

# Supprimer les EIPs
if [ "$CLEANUP_ALL" = true ] || [ "$CLEANUP_NETWORK" = true ]; then
  echo "Nettoyage des adresses IP élastiques..."
  for eip in $(aws ec2 describe-addresses --region $AWS_REGION --query 'Addresses[].AllocationId' --output text); do
    echo "Suppression de l'EIP: $eip"
    aws ec2 release-address --region $AWS_REGION --allocation-id $eip
  done
fi

# Supprimer les key pairs
if [ "$CLEANUP_ALL" = true ] || [ "$CLEANUP_COMPUTE" = true ]; then
  echo "Nettoyage des paires de clés SSH..."
  for key in $(aws ec2 describe-key-pairs --region $AWS_REGION --query 'KeyPairs[].KeyName' --output text); do
    echo "Suppression de la key pair: $key"
    aws ec2 delete-key-pair --region $AWS_REGION --key-name $key
  done
fi

# Supprimer les bases de données RDS
if [ "$CLEANUP_ALL" = true ] || [ "$CLEANUP_STORAGE" = true ]; then
  echo "Nettoyage des bases de données RDS..."
  for db in $(aws rds describe-db-instances --region $AWS_REGION --query 'DBInstances[].DBInstanceIdentifier' --output text); do
    echo "Suppression de la base de données RDS: $db"
    aws rds delete-db-instance --region $AWS_REGION --db-instance-identifier $db --skip-final-snapshot --delete-automated-backups
    echo "Attente de la suppression de la base de données..."
    aws rds wait db-instance-deleted --region $AWS_REGION --db-instance-identifier $db
  done

  # Supprimer les groupes de sous-réseaux RDS
  echo "Nettoyage des groupes de sous-réseaux RDS..."
  for subnet_group in $(aws rds describe-db-subnet-groups --region $AWS_REGION --query 'DBSubnetGroups[].DBSubnetGroupName' --output text); do
    echo "Suppression du groupe de sous-réseaux RDS: $subnet_group"
    aws rds delete-db-subnet-group --region $AWS_REGION --db-subnet-group-name $subnet_group
  done
fi

# Supprimer les load balancers
if [ "$CLEANUP_ALL" = true ] || [ "$CLEANUP_NETWORK" = true ]; then
  echo "Nettoyage des load balancers..."
  for lb in $(aws elbv2 describe-load-balancers --region $AWS_REGION --query 'LoadBalancers[].LoadBalancerArn' --output text); do
    echo "Suppression du load balancer: $lb"
    aws elbv2 delete-load-balancer --region $AWS_REGION --load-balancer-arn $lb
  done

  echo "Attente après la suppression des load balancers..."
  sleep 60

  # Supprimer les target groups
  echo "Nettoyage des target groups..."
  for tg in $(aws elbv2 describe-target-groups --region $AWS_REGION --query 'TargetGroups[].TargetGroupArn' --output text); do
    echo "Suppression du target group: $tg"
    aws elbv2 delete-target-group --region $AWS_REGION --target-group-arn $tg
  done
fi

# Supprimer les NAT gateways
if [ "$CLEANUP_ALL" = true ] || [ "$CLEANUP_NETWORK" = true ]; then
  echo "Nettoyage des NAT gateways..."
  for nat in $(aws ec2 describe-nat-gateways --region $AWS_REGION --filter "Name=state,Values=available" --query 'NatGateways[].NatGatewayId' --output text); do
    echo "Suppression de la NAT gateway: $nat"
    aws ec2 delete-nat-gateway --region $AWS_REGION --nat-gateway-id $nat
  done

  echo "Attente de la suppression des NAT gateways..."
  sleep 120
fi

# Supprimer les groupes de sécurité (sauf le groupe par défaut)
if [ "$CLEANUP_ALL" = true ] || [ "$CLEANUP_NETWORK" = true ]; then
  echo "Nettoyage des groupes de sécurité..."
  for sg in $(aws ec2 describe-security-groups --region $AWS_REGION --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text); do
    echo "Suppression du groupe de sécurité: $sg"
    aws ec2 delete-security-group --region $AWS_REGION --group-id $sg || true
  done
fi

# Supprimer les tables DynamoDB
if [ "$CLEANUP_ALL" = true ] || [ "$CLEANUP_OTHER" = true ]; then
  echo "Nettoyage des tables DynamoDB..."
  for table in $(aws dynamodb list-tables --region $AWS_REGION --query 'TableNames[]' --output text); do
    echo "Suppression de la table DynamoDB: $table"
    aws dynamodb delete-table --region $AWS_REGION --table-name $table
  done
fi

# Supprimer les passerelles Internet
if [ "$CLEANUP_ALL" = true ] || [ "$CLEANUP_NETWORK" = true ]; then
  echo "Nettoyage des passerelles Internet..."
  for vpc in $(aws ec2 describe-vpcs --region $AWS_REGION --query 'Vpcs[].VpcId' --output text); do
    for igw in $(aws ec2 describe-internet-gateways --region $AWS_REGION --filters "Name=attachment.vpc-id,Values=$vpc" --query 'InternetGateways[].InternetGatewayId' --output text); do
      echo "Détachement de la passerelle Internet: $igw du VPC: $vpc"
      aws ec2 detach-internet-gateway --region $AWS_REGION --internet-gateway-id $igw --vpc-id $vpc
      echo "Suppression de la passerelle Internet: $igw"
      aws ec2 delete-internet-gateway --region $AWS_REGION --internet-gateway-id $igw
    done
  done
fi

# Supprimer les sous-réseaux
if [ "$CLEANUP_ALL" = true ] || [ "$CLEANUP_NETWORK" = true ]; then
  echo "Nettoyage des sous-réseaux..."
  for subnet in $(aws ec2 describe-subnets --region $AWS_REGION --query 'Subnets[].SubnetId' --output text); do
    echo "Suppression du subnet: $subnet"
    aws ec2 delete-subnet --region $AWS_REGION --subnet-id $subnet || true
  done
fi

# Supprimer les tables de routage (sauf la principale)
if [ "$CLEANUP_ALL" = true ] || [ "$CLEANUP_NETWORK" = true ]; then
  echo "Nettoyage des tables de routage..."
  for rt in $(aws ec2 describe-route-tables --region $AWS_REGION --query 'RouteTables[?Associations[0].Main!=`true`].RouteTableId' --output text); do
    echo "Suppression de la table de routage: $rt"
    aws ec2 delete-route-table --region $AWS_REGION --route-table-id $rt || true
  done
fi

# Supprimer les VPCs
if [ "$CLEANUP_ALL" = true ] || [ "$CLEANUP_NETWORK" = true ]; then
  echo "Nettoyage des VPCs..."
  for vpc in $(aws ec2 describe-vpcs --region $AWS_REGION --query 'Vpcs[].VpcId' --output text); do
    echo "Suppression du VPC: $vpc"
    aws ec2 delete-vpc --region $AWS_REGION --vpc-id $vpc || true
  done
fi

# Supprimer les buckets S3
if [ "$CLEANUP_ALL" = true ] || [ "$CLEANUP_STORAGE" = true ]; then
  echo "Nettoyage des buckets S3..."
  for bucket in $(aws s3api list-buckets --query 'Buckets[].Name' --output text); do
    # Vérifier si le bucket est dans la région spécifiée
    region=$(aws s3api get-bucket-location --bucket $bucket --query 'LocationConstraint' --output text 2>/dev/null || echo "us-east-1")
    if [ "$region" = "None" ]; then region="us-east-1"; fi
    if [ "$region" = "$AWS_REGION" ]; then
      echo "Suppression du bucket S3: $bucket dans la région $AWS_REGION"
      # Vider le bucket d'abord
      aws s3 rm s3://$bucket --recursive
      # Supprimer le bucket
      aws s3api delete-bucket --bucket $bucket --region $AWS_REGION
    fi
  done
fi

# Supprimer les groupes de logs CloudWatch
if [ "$CLEANUP_ALL" = true ] || [ "$CLEANUP_OTHER" = true ]; then
  echo "Nettoyage des groupes de logs CloudWatch..."
  for log_group in $(aws logs describe-log-groups --region $AWS_REGION --query 'logGroups[].logGroupName' --output text); do
    echo "Suppression du groupe de logs CloudWatch: $log_group"
    aws logs delete-log-group --region $AWS_REGION --log-group-name $log_group
  done
fi

echo "Nettoyage terminé dans la région $AWS_REGION!"