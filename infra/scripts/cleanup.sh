#!/bin/bash
# Script pour nettoyer les ressources AWS existantes

# Configurer la région
export AWS_REGION=ca-central-1

echo "Suppression des ressources AWS dans la région $AWS_REGION..."

# Supprimer les clusters EKS
for cluster in $(aws eks list-clusters --region $AWS_REGION --query 'clusters[]' --output text); do
  echo "Suppression du cluster EKS: $cluster"
  aws eks delete-nodegroup --region $AWS_REGION --cluster-name $cluster --nodegroup-name $(aws eks list-nodegroups --region $AWS_REGION --cluster-name $cluster --query 'nodegroups[0]' --output text) --no-paginate
  aws eks delete-cluster --region $AWS_REGION --name $cluster
done

# Supprimer les instances EC2
for instance in $(aws ec2 describe-instances --region $AWS_REGION --filters "Name=tag:Project,Values=projet-c" --query 'Reservations[].Instances[].InstanceId' --output text); do
  echo "Suppression de l'instance EC2: $instance"
  aws ec2 terminate-instances --region $AWS_REGION --instance-ids $instance
done

# Supprimer les EIPs
for eip in $(aws ec2 describe-addresses --region $AWS_REGION --query 'Addresses[].AllocationId' --output text); do
  echo "Suppression de l'EIP: $eip"
  aws ec2 release-address --region $AWS_REGION --allocation-id $eip
done

# Supprimer les key pairs
for key in $(aws ec2 describe-key-pairs --region $AWS_REGION --filters "Name=key-name,Values=projet-c*" --query 'KeyPairs[].KeyName' --output text); do
  echo "Suppression de la key pair: $key"
  aws ec2 delete-key-pair --region $AWS_REGION --key-name $key
done

# Supprimer les bases de données RDS
for db in $(aws rds describe-db-instances --region $AWS_REGION --query 'DBInstances[?starts_with(DBInstanceIdentifier, `projet-c`)].DBInstanceIdentifier' --output text); do
  echo "Suppression de la base de données RDS: $db"
  aws rds delete-db-instance --region $AWS_REGION --db-instance-identifier $db --skip-final-snapshot
done

# Supprimer les VPCs (attendre que les autres ressources soient supprimées)
echo "Attente de 5 minutes pour la suppression des ressources dépendantes..."
sleep 300

for vpc in $(aws ec2 describe-vpcs --region $AWS_REGION --filters "Name=tag:Project,Values=projet-c" --query 'Vpcs[].VpcId' --output text); do
  # Supprimer les sous-réseaux
  for subnet in $(aws ec2 describe-subnets --region $AWS_REGION --filters "Name=vpc-id,Values=$vpc" --query 'Subnets[].SubnetId' --output text); do
    echo "Suppression du subnet: $subnet"
    aws ec2 delete-subnet --region $AWS_REGION --subnet-id $subnet
  done
  
  # Supprimer les groupes de sécurité
  for sg in $(aws ec2 describe-security-groups --region $AWS_REGION --filters "Name=vpc-id,Values=$vpc" --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text); do
    echo "Suppression du groupe de sécurité: $sg"
    aws ec2 delete-security-group --region $AWS_REGION --group-id $sg
  done
  
  # Supprimer les tables de routage
  for rt in $(aws ec2 describe-route-tables --region $AWS_REGION --filters "Name=vpc-id,Values=$vpc" --query 'RouteTables[?Associations[0].Main!=`true`].RouteTableId' --output text); do
    echo "Suppression de la table de routage: $rt"
    aws ec2 delete-route-table --region $AWS_REGION --route-table-id $rt
  done
  
  # Supprimer les passerelles Internet
  for igw in $(aws ec2 describe-internet-gateways --region $AWS_REGION --filters "Name=attachment.vpc-id,Values=$vpc" --query 'InternetGateways[].InternetGatewayId' --output text); do
    echo "Détachement de la passerelle Internet: $igw du VPC: $vpc"
    aws ec2 detach-internet-gateway --region $AWS_REGION --internet-gateway-id $igw --vpc-id $vpc
    echo "Suppression de la passerelle Internet: $igw"
    aws ec2 delete-internet-gateway --region $AWS_REGION --internet-gateway-id $igw
  done
  
  # Supprimer les NAT gateways
  for nat in $(aws ec2 describe-nat-gateways --region $AWS_REGION --filter "Name=vpc-id,Values=$vpc" --query 'NatGateways[].NatGatewayId' --output text); do
    echo "Suppression de la NAT gateway: $nat"
    aws ec2 delete-nat-gateway --region $AWS_REGION --nat-gateway-id $nat
  done
  
  # Supprimer le VPC
  echo "Suppression du VPC: $vpc"
  aws ec2 delete-vpc --region $AWS_REGION --vpc-id $vpc
done

echo "Nettoyage terminé dans la région $AWS_REGION!"