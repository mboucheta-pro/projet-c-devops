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

# Fonction pour attendre que les ressources soient supprimées
wait_for_deletion() {
  local resource_type=$1
  local resource_id=$2
  local max_attempts=${3:-30}
  local attempt=0
  
  echo "Attente de la suppression de $resource_type: $resource_id"
  while [ $attempt -lt $max_attempts ]; do
    if ! aws $resource_type describe-$resource_id --region $AWS_REGION &>/dev/null; then
      echo "$resource_type $resource_id supprimé avec succès"
      return 0
    fi
    echo "Attente de la suppression... ($((attempt+1))/$max_attempts)"
    sleep 10
    ((attempt++))
  done
  echo "Délai d'attente dépassé pour la suppression de $resource_type: $resource_id"
  return 1
}

# 1. Détacher les EIPs des instances
if [ "$CLEANUP_ALL" = true ] || [ "$CLEANUP_NETWORK" = true ]; then
  echo "Détachement des adresses IP élastiques des instances..."
  for assoc in $(aws ec2 describe-addresses --region $AWS_REGION --query 'Addresses[?AssociationId!=null].AssociationId' --output text); do
    echo "Détachement de l'association EIP: $assoc"
    aws ec2 disassociate-address --region $AWS_REGION --association-id $assoc || true
    sleep 2
  done
fi

# 2. Supprimer les clusters EKS
if [ "$CLEANUP_ALL" = true ] || [ "$CLEANUP_COMPUTE" = true ]; then
  echo "Nettoyage des clusters EKS..."
  for cluster in $(aws eks list-clusters --region $AWS_REGION --query 'clusters[]' --output text); do
    echo "Suppression du cluster EKS: $cluster"
    # Supprimer les fargate profiles s'ils existent
    for profile in $(aws eks list-fargate-profiles --region $AWS_REGION --cluster-name $cluster --query 'fargateProfileNames[]' --output text 2>/dev/null || echo ""); do
      echo "Suppression du fargate profile: $profile du cluster: $cluster"
      aws eks delete-fargate-profile --region $AWS_REGION --cluster-name $cluster --fargate-profile-name $profile || true
      # Attendre la suppression du profil
      while aws eks describe-fargate-profile --region $AWS_REGION --cluster-name $cluster --fargate-profile-name $profile &>/dev/null; do
        echo "Attente de la suppression du fargate profile..."
        sleep 10
      done
    done
    
    # Supprimer les nodegroups
    for nodegroup in $(aws eks list-nodegroups --region $AWS_REGION --cluster-name $cluster --query 'nodegroups[]' --output text 2>/dev/null || echo ""); do
      echo "Suppression du nodegroup: $nodegroup du cluster: $cluster"
      aws eks delete-nodegroup --region $AWS_REGION --cluster-name $cluster --nodegroup-name $nodegroup --no-paginate || true
      echo "Attente de la suppression du nodegroup..."
      aws eks wait nodegroup-deleted --region $AWS_REGION --cluster-name $cluster --nodegroup-name $nodegroup || true
    done
    
    # Supprimer les addons
    for addon in $(aws eks list-addons --region $AWS_REGION --cluster-name $cluster --query 'addons[]' --output text 2>/dev/null || echo ""); do
      echo "Suppression de l'addon: $addon du cluster: $cluster"
      aws eks delete-addon --region $AWS_REGION --cluster-name $cluster --addon-name $addon --force || true
    done
    
    # Supprimer le cluster
    aws eks delete-cluster --region $AWS_REGION --name $cluster || true
    echo "Attente de la suppression du cluster..."
    aws eks wait cluster-deleted --region $AWS_REGION --name $cluster || true
  done
fi

# 3. Supprimer les instances EC2
if [ "$CLEANUP_ALL" = true ] || [ "$CLEANUP_COMPUTE" = true ]; then
  echo "Nettoyage des instances EC2..."
  for instance in $(aws ec2 describe-instances --region $AWS_REGION --filters "Name=instance-state-name,Values=running,stopped,pending,stopping" --query 'Reservations[].Instances[].InstanceId' --output text); do
    echo "Suppression de l'instance EC2: $instance"
    # Désactiver la protection contre la résiliation
    aws ec2 modify-instance-attribute --region $AWS_REGION --instance-id $instance --no-disable-api-termination || true
    # Terminer l'instance
    aws ec2 terminate-instances --region $AWS_REGION --instance-ids $instance || true
  done

  # Attendre que les instances soient terminées
  echo "Attente de la terminaison des instances..."
  aws ec2 wait instance-terminated --region $AWS_REGION --filters "Name=instance-state-name,Values=terminated" || true
  sleep 30
fi

# 4. Supprimer les load balancers
if [ "$CLEANUP_ALL" = true ] || [ "$CLEANUP_NETWORK" = true ]; then
  echo "Nettoyage des load balancers..."
  for lb in $(aws elbv2 describe-load-balancers --region $AWS_REGION --query 'LoadBalancers[].LoadBalancerArn' --output text); do
    echo "Suppression du load balancer: $lb"
    aws elbv2 delete-load-balancer --region $AWS_REGION --load-balancer-arn $lb || true
  done

  echo "Attente après la suppression des load balancers..."
  sleep 30

  # Supprimer les target groups
  echo "Nettoyage des target groups..."
  for tg in $(aws elbv2 describe-target-groups --region $AWS_REGION --query 'TargetGroups[].TargetGroupArn' --output text); do
    echo "Suppression du target group: $tg"
    aws elbv2 delete-target-group --region $AWS_REGION --target-group-arn $tg || true
  done
  
  sleep 10
fi

# 5. Supprimer les NAT gateways
if [ "$CLEANUP_ALL" = true ] || [ "$CLEANUP_NETWORK" = true ]; then
  echo "Nettoyage des NAT gateways..."
  for nat in $(aws ec2 describe-nat-gateways --region $AWS_REGION --filter "Name=state,Values=available,pending" --query 'NatGateways[].NatGatewayId' --output text); do
    echo "Suppression de la NAT gateway: $nat"
    aws ec2 delete-nat-gateway --region $AWS_REGION --nat-gateway-id $nat || true
  done

  echo "Attente de la suppression des NAT gateways..."
  sleep 60
  
  # Vérifier que toutes les NAT gateways sont supprimées ou en cours de suppression
  for nat in $(aws ec2 describe-nat-gateways --region $AWS_REGION --query 'NatGateways[].NatGatewayId' --output text); do
    state=$(aws ec2 describe-nat-gateways --region $AWS_REGION --nat-gateway-ids $nat --query 'NatGateways[0].State' --output text)
    if [ "$state" != "deleted" ] && [ "$state" != "deleting" ]; then
      echo "La NAT gateway $nat est toujours dans l'état $state, tentative de suppression..."
      aws ec2 delete-nat-gateway --region $AWS_REGION --nat-gateway-id $nat || true
    fi
  done
  
  sleep 30
fi

# 6. Maintenant libérer les EIPs
if [ "$CLEANUP_ALL" = true ] || [ "$CLEANUP_NETWORK" = true ]; then
  echo "Suppression des adresses IP élastiques..."
  for eip in $(aws ec2 describe-addresses --region $AWS_REGION --query 'Addresses[].AllocationId' --output text); do
    echo "Suppression de l'EIP: $eip"
    aws ec2 release-address --region $AWS_REGION --allocation-id $eip || true
    sleep 1
  done
fi

# 7. Supprimer les key pairs
if [ "$CLEANUP_ALL" = true ] || [ "$CLEANUP_COMPUTE" = true ]; then
  echo "Nettoyage des paires de clés SSH..."
  for key in $(aws ec2 describe-key-pairs --region $AWS_REGION --query 'KeyPairs[].KeyName' --output text); do
    echo "Suppression de la key pair: $key"
    aws ec2 delete-key-pair --region $AWS_REGION --key-name $key || true
  done
fi

# 8. Supprimer les bases de données RDS
if [ "$CLEANUP_ALL" = true ] || [ "$CLEANUP_STORAGE" = true ]; then
  echo "Nettoyage des bases de données RDS..."
  for db in $(aws rds describe-db-instances --region $AWS_REGION --query 'DBInstances[].DBInstanceIdentifier' --output text); do
    echo "Suppression de la base de données RDS: $db"
    # Désactiver la protection contre la suppression si elle est activée
    aws rds modify-db-instance --region $AWS_REGION --db-instance-identifier $db --no-deletion-protection --apply-immediately || true
    # Supprimer l'instance sans snapshot final et supprimer les sauvegardes automatiques
    aws rds delete-db-instance --region $AWS_REGION --db-instance-identifier $db --skip-final-snapshot --delete-automated-backups || true
    echo "Attente de la suppression de la base de données..."
    aws rds wait db-instance-deleted --region $AWS_REGION --db-instance-identifier $db || true
  done

  # Supprimer les groupes de sous-réseaux RDS
  echo "Nettoyage des groupes de sous-réseaux RDS..."
  for subnet_group in $(aws rds describe-db-subnet-groups --region $AWS_REGION --query 'DBSubnetGroups[].DBSubnetGroupName' --output text); do
    echo "Suppression du groupe de sous-réseaux RDS: $subnet_group"
    aws rds delete-db-subnet-group --region $AWS_REGION --db-subnet-group-name $subnet_group || true
  done
  
  sleep 10
fi

# 9. Supprimer les tables DynamoDB
if [ "$CLEANUP_ALL" = true ] || [ "$CLEANUP_OTHER" = true ]; then
  echo "Nettoyage des tables DynamoDB..."
  for table in $(aws dynamodb list-tables --region $AWS_REGION --query 'TableNames[]' --output text); do
    echo "Suppression de la table DynamoDB: $table"
    aws dynamodb delete-table --region $AWS_REGION --table-name $table || true
  done
  
  sleep 10
fi

# 10. Supprimer les groupes de sécurité (sauf le groupe par défaut)
if [ "$CLEANUP_ALL" = true ] || [ "$CLEANUP_NETWORK" = true ]; then
  echo "Nettoyage des groupes de sécurité..."
  # Supprimer d'abord les règles de sécurité entrantes et sortantes pour éviter les dépendances
  for sg in $(aws ec2 describe-security-groups --region $AWS_REGION --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text); do
    echo "Suppression des règles du groupe de sécurité: $sg"
    # Supprimer les règles entrantes
    INBOUND_RULES=$(aws ec2 describe-security-groups --region $AWS_REGION --group-id $sg --query 'SecurityGroups[0].IpPermissions' --output json)
    if [ "$INBOUND_RULES" != "[]" ] && [ "$INBOUND_RULES" != "null" ]; then
      aws ec2 revoke-security-group-ingress --region $AWS_REGION --group-id $sg --ip-permissions "$INBOUND_RULES" || true
    fi
    # Supprimer les règles sortantes
    OUTBOUND_RULES=$(aws ec2 describe-security-groups --region $AWS_REGION --group-id $sg --query 'SecurityGroups[0].IpPermissionsEgress' --output json)
    if [ "$OUTBOUND_RULES" != "[]" ] && [ "$OUTBOUND_RULES" != "null" ]; then
      aws ec2 revoke-security-group-egress --region $AWS_REGION --group-id $sg --ip-permissions "$OUTBOUND_RULES" || true
    fi
  done
  
  # Attendre un peu pour que les modifications se propagent
  sleep 10
  
  # Maintenant supprimer les groupes de sécurité
  for sg in $(aws ec2 describe-security-groups --region $AWS_REGION --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text); do
    echo "Suppression du groupe de sécurité: $sg"
    aws ec2 delete-security-group --region $AWS_REGION --group-id $sg || true
    sleep 1
  done
  
  sleep 10
fi

# 11. Supprimer les DHCP option sets
if [ "$CLEANUP_ALL" = true ] || [ "$CLEANUP_NETWORK" = true ]; then
  echo "Nettoyage des DHCP option sets..."
  # Récupérer l'ID du DHCP option set par défaut
  DEFAULT_DHCP=$(aws ec2 describe-vpcs --region $AWS_REGION --query 'Vpcs[0].DhcpOptionsId' --output text)
  
  # Supprimer les DHCP option sets non par défaut
  for dhcp in $(aws ec2 describe-dhcp-options --region $AWS_REGION --query 'DhcpOptions[?DhcpOptionsId!=`'$DEFAULT_DHCP'`].DhcpOptionsId' --output text); do
    echo "Suppression du DHCP option set: $dhcp"
    aws ec2 delete-dhcp-options --region $AWS_REGION --dhcp-options-id $dhcp || true
  done
  
  sleep 5
fi

# 12. Supprimer les passerelles Internet
if [ "$CLEANUP_ALL" = true ] || [ "$CLEANUP_NETWORK" = true ]; then
  echo "Nettoyage des passerelles Internet..."
  for vpc in $(aws ec2 describe-vpcs --region $AWS_REGION --query 'Vpcs[].VpcId' --output text); do
    for igw in $(aws ec2 describe-internet-gateways --region $AWS_REGION --filters "Name=attachment.vpc-id,Values=$vpc" --query 'InternetGateways[].InternetGatewayId' --output text); do
      echo "Détachement de la passerelle Internet: $igw du VPC: $vpc"
      aws ec2 detach-internet-gateway --region $AWS_REGION --internet-gateway-id $igw --vpc-id $vpc || true
      sleep 2
      echo "Suppression de la passerelle Internet: $igw"
      aws ec2 delete-internet-gateway --region $AWS_REGION --internet-gateway-id $igw || true
    done
  done
  
  sleep 10
fi

# 13. Supprimer les sous-réseaux
if [ "$CLEANUP_ALL" = true ] || [ "$CLEANUP_NETWORK" = true ]; then
  echo "Nettoyage des sous-réseaux..."
  for subnet in $(aws ec2 describe-subnets --region $AWS_REGION --query 'Subnets[].SubnetId' --output text); do
    echo "Suppression du subnet: $subnet"
    aws ec2 delete-subnet --region $AWS_REGION --subnet-id $subnet || true
    sleep 1
  done
  
  sleep 10
fi

# 14. Supprimer les tables de routage (sauf la principale)
if [ "$CLEANUP_ALL" = true ] || [ "$CLEANUP_NETWORK" = true ]; then
  echo "Nettoyage des tables de routage..."
  # Supprimer d'abord les associations de sous-réseaux
  for rt in $(aws ec2 describe-route-tables --region $AWS_REGION --query 'RouteTables[?Associations[0].Main!=`true`].RouteTableId' --output text); do
    for assoc in $(aws ec2 describe-route-tables --region $AWS_REGION --route-table-id $rt --query 'RouteTables[0].Associations[?Main!=`true`].RouteTableAssociationId' --output text); do
      echo "Suppression de l'association de table de routage: $assoc"
      aws ec2 disassociate-route-table --region $AWS_REGION --association-id $assoc || true
    done
    
    # Supprimer les routes
    for route in $(aws ec2 describe-route-tables --region $AWS_REGION --route-table-id $rt --query 'RouteTables[0].Routes[?Origin==`CreateRoute`].DestinationCidrBlock' --output text); do
      echo "Suppression de la route $route de la table $rt"
      aws ec2 delete-route --region $AWS_REGION --route-table-id $rt --destination-cidr-block $route || true
    done
    
    echo "Suppression de la table de routage: $rt"
    aws ec2 delete-route-table --region $AWS_REGION --route-table-id $rt || true
  done
  
  sleep 10
fi

# 15. Supprimer les VPCs
if [ "$CLEANUP_ALL" = true ] || [ "$CLEANUP_NETWORK" = true ]; then
  echo "Nettoyage des VPCs..."
  for vpc in $(aws ec2 describe-vpcs --region $AWS_REGION --query 'Vpcs[].VpcId' --output text); do
    echo "Suppression du VPC: $vpc"
    aws ec2 delete-vpc --region $AWS_REGION --vpc-id $vpc || true
    sleep 2
  done
fi

# 16. Supprimer les buckets S3
if [ "$CLEANUP_ALL" = true ] || [ "$CLEANUP_STORAGE" = true ]; then
  echo "Nettoyage des buckets S3..."
  for bucket in $(aws s3api list-buckets --query 'Buckets[].Name' --output text); do
    # Vérifier si le bucket est dans la région spécifiée
    region=$(aws s3api get-bucket-location --bucket $bucket --query 'LocationConstraint' --output text 2>/dev/null || echo "us-east-1")
    if [ "$region" = "None" ]; then region="us-east-1"; fi
    if [ "$region" = "$AWS_REGION" ]; then
      echo "Suppression du bucket S3: $bucket dans la région $AWS_REGION"
      # Désactiver la protection contre la suppression
      aws s3api put-bucket-versioning --bucket $bucket --versioning-configuration Status=Suspended || true
      
      # Supprimer tous les objets, y compris les versions et les marqueurs de suppression
      echo "Suppression des versions d'objets..."
      versions=$(aws s3api list-object-versions --bucket $bucket --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' --output json 2>/dev/null || echo '{"Objects":[]}')
      if [ "$(echo $versions | jq -r '.Objects | length')" -gt 0 ]; then
        echo $versions | jq -c > /tmp/delete_versions.json
        aws s3api delete-objects --bucket $bucket --delete file:///tmp/delete_versions.json || true
      fi
      
      echo "Suppression des marqueurs de suppression..."
      markers=$(aws s3api list-object-versions --bucket $bucket --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' --output json 2>/dev/null || echo '{"Objects":[]}')
      if [ "$(echo $markers | jq -r '.Objects | length')" -gt 0 ]; then
        echo $markers | jq -c > /tmp/delete_markers.json
        aws s3api delete-objects --bucket $bucket --delete file:///tmp/delete_markers.json || true
      fi
      
      # Vider le bucket avec la méthode standard (pour les objets restants)
      echo "Suppression des objets restants..."
      aws s3 rm s3://$bucket --recursive --force || true
      
      # Supprimer le bucket
      echo "Suppression du bucket..."
      aws s3api delete-bucket --bucket $bucket --region $AWS_REGION || true
    fi
  done
fi

# 17. Supprimer les groupes de logs CloudWatch
if [ "$CLEANUP_ALL" = true ] || [ "$CLEANUP_OTHER" = true ]; then
  echo "Nettoyage des groupes de logs CloudWatch..."
  for log_group in $(aws logs describe-log-groups --region $AWS_REGION --query 'logGroups[].logGroupName' --output text); do
    echo "Suppression du groupe de logs CloudWatch: $log_group"
    aws logs delete-log-group --region $AWS_REGION --log-group-name $log_group || true
  done
fi

echo "Nettoyage terminé dans la région $AWS_REGION!"