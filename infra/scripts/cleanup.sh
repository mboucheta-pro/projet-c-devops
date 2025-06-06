#!/bin/bash
# Script pour nettoyer les ressources AWS existantes

# Configurer la région
export AWS_REGION=ca-central-1

echo "Suppression des ressources AWS..."

# Supprimer les clusters EKS
for cluster in $(aws eks list-clusters --query 'clusters[]' --output text); do
  echo "Suppression du cluster EKS: $cluster"
  aws eks delete-nodegroup --cluster-name $cluster --nodegroup-name $(aws eks list-nodegroups --cluster-name $cluster --query 'nodegroups[0]' --output text) --no-paginate
  aws eks delete-cluster --name $cluster
done

# Supprimer les instances EC2
for instance in $(aws ec2 describe-instances --filters "Name=tag:Project,Values=projet-c" --query 'Reservations[].Instances[].InstanceId' --output text); do
  echo "Suppression de l'instance EC2: $instance"
  aws ec2 terminate-instances --instance-ids $instance
done

# Supprimer les EIPs
for eip in $(aws ec2 describe-addresses --query 'Addresses[].AllocationId' --output text); do
  echo "Suppression de l'EIP: $eip"
  aws ec2 release-address --allocation-id $eip
done

# Supprimer les key pairs
for key in $(aws ec2 describe-key-pairs --filters "Name=key-name,Values=projet-c*" --query 'KeyPairs[].KeyName' --output text); do
  echo "Suppression de la key pair: $key"
  aws ec2 delete-key-pair --key-name $key
done

# Supprimer les bases de données RDS
for db in $(aws rds describe-db-instances --query 'DBInstances[?starts_with(DBInstanceIdentifier, `projet-c`)].DBInstanceIdentifier' --output text); do
  echo "Suppression de la base de données RDS: $db"
  aws rds delete-db-instance --db-instance-identifier $db --skip-final-snapshot
done

# Supprimer les VPCs (attendre que les autres ressources soient supprimées)
echo "Attente de 5 minutes pour la suppression des ressources dépendantes..."
sleep 300

for vpc in $(aws ec2 describe-vpcs --filters "Name=tag:Project,Values=projet-c" --query 'Vpcs[].VpcId' --output text); do
  # Supprimer les sous-réseaux
  for subnet in $(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpc" --query 'Subnets[].SubnetId' --output text); do
    echo "Suppression du subnet: $subnet"
    aws ec2 delete-subnet --subnet-id $subnet
  done
  
  # Supprimer les groupes de sécurité
  for sg in $(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$vpc" --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text); do
    echo "Suppression du groupe de sécurité: $sg"
    aws ec2 delete-security-group --group-id $sg
  done
  
  # Supprimer les tables de routage
  for rt in $(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$vpc" --query 'RouteTables[?Associations[0].Main!=`true`].RouteTableId' --output text); do
    echo "Suppression de la table de routage: $rt"
    aws ec2 delete-route-table --route-table-id $rt
  done
  
  # Supprimer les passerelles Internet
  for igw in $(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$vpc" --query 'InternetGateways[].InternetGatewayId' --output text); do
    echo "Détachement de la passerelle Internet: $igw du VPC: $vpc"
    aws ec2 detach-internet-gateway --internet-gateway-id $igw --vpc-id $vpc
    echo "Suppression de la passerelle Internet: $igw"
    aws ec2 delete-internet-gateway --internet-gateway-id $igw
  done
  
  # Supprimer les NAT gateways
  for nat in $(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$vpc" --query 'NatGateways[].NatGatewayId' --output text); do
    echo "Suppression de la NAT gateway: $nat"
    aws ec2 delete-nat-gateway --nat-gateway-id $nat
  done
  
  # Supprimer le VPC
  echo "Suppression du VPC: $vpc"
  aws ec2 delete-vpc --vpc-id $vpc
done

echo "Nettoyage terminé!"