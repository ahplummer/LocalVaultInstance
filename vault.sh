#!/bin/bash

# Output colors
NORMAL="\\033[0;39m"
RED="\\033[1;31m"
BLUE="\\033[1;34m"
export AWS_PAGER=""

log() {
  echo -e -n "$BLUE > $1 $NORMAL\n"
}

error() {
  echo ""
  echo -e -n "$RED >>> ERROR - $1$NORMAL\n"
}
help() {
  echo "-----------------------------------------------------------------------"
  echo "                      Available commands                              -"
  echo "-----------------------------------------------------------------------"
  echo -e -n "$BLUE"
  echo "   > initLocal - initialize a Vault instance using local file system"
  echo "   > initS3 - initialize a Vault instance using S3 Backing"
  echo "   > destroyLocal - destroys a local Vault environment"
  echo "   > destroyS3 - destroys Vault environment, S3 infra"
  echo "   > ----------------------"
  echo "   > startVault - starts a pre-initialized Vault container"
  echo "   > stopVault - stops a running Vault container, not destructive"
  echo "   > ----------------------"
  echo "   > setSecret - sets a secret, requires 3 additional parms"
  echo "   > getSecret - gets a secret, requires 2 additional parms"
  echo "   > ----------------------"  
  echo "   > help - Display this help"
  echo -e -n "$NORMAL"
  echo "-----------------------------------------------------------------------"

}

destroyLocal(){
  stopVaultDocker
	rm -rf ./file
  rm -rf .env
  log "Removed Local Environment"
}
initLocal(){
  destroyLocal #destroy things first.
  setLocalEnv
  startVaultDocker
  initializeVault
}
destroyS3(){
  source .env
  stopVaultDocker
  if [ -z "${AWS_S3_BUCKET}" ]
  then
    log "Will NOT attempt to remove S3..."
  else
    aws s3 rb s3://$(echo $AWS_S3_BUCKET) --force
  fi
  rm -rf .env
  log "Removed S3 Environment"
}
initS3(){
  destroyS3 #destroy things first.
  setS3Env
  startVaultDocker
  initializeVault
}
setS3Env(){
  aws configure
  export randstring=$(openssl rand -hex 10)
  echo \#\!/bin/bash > .env
	echo export VAULT_ADDR=http://0.0.0.0:8200 >> .env
	echo export AWS_S3_BUCKET=vault-$(echo $randstring) >> .env	
	aws s3 mb --region=us-east-1 s3://vault-$(echo $randstring)
	echo export VAULT_CONFIG=/vault/config/vaultS3.json >> .env
	echo export AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id) >> .env
	echo export AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key) >> .env
	#aws s3api put-public-access-block --bucket vault-$(randomstring) --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
}

setLocalEnv(){
  echo \#\!/bin/bash > .env
	echo export VAULT_ADDR=http://0.0.0.0:8200 >> .env
	echo export VAULT_CONFIG=/vault/config/vaultfile.json >> .env
}
startVaultDocker(){
  if [ -f ".env" ]
  then
    log "Found vault environment..."
    source .env
  else
    error "For this command, you'll need a pre-configured Vault instance; try './vault.sh initS3' or './vault.sh' initLocal"
    exit 1
  fi
  docker-compose up -d
  log "Sleeping a bit for container to stand up"
  sleep 5
  if [ -z "${UNSEAL_TOKEN}" ]
  then
    log "Will NOT attempt to unseal right now..."
  else
    vault operator unseal $UNSEAL_TOKEN
  fi
  log "Started Vault Docker Container"
}
stopVaultDocker(){
  docker-compose down
  log "Stopped Vault Docker Container"
}
initializeVault(){
  source .env
	vault operator init -key-shares=1 -key-threshold=1 > initoutput
  export roottoken=$(cat initoutput | grep Root | awk '{print $4}')
  export unsealtoken=$(cat initoutput | grep Unseal | awk '{print $4}')
	echo export ROOT_TOKEN=$roottoken >> .env
  echo export UNSEAL_TOKEN=$unsealtoken >> .env
  sleep 2
	vault operator unseal $unsealtoken
	rm -rf initoutput
  vault secrets enable kv-v2
}
setSecret(){
  if [ -f ".env" ]
  then
    source .env
  else
    error "For this command, you'll need a pre-configured Vault instance; try './vault.sh initS3' or './vault.sh' initLocal"
    exit 1
  fi
  vault login $ROOT_TOKEN >/dev/null
  vault kv put kv-v2/$1 $2=$3
}
getSecret(){
  if [ -f ".env" ]
  then
    source .env
  else
    error "For this command, you'll need a pre-configured Vault instance; try './vault.sh initS3' or './vault.sh' initLocal"
    exit 1
  fi
  vault login $ROOT_TOKEN >/dev/null
  export secret=$(VAULT_FORMAT=json vault kv get kv-v2/$1 | jq -r '.data.data.'$2)
  echo $secret
}


# Check at least 1 argument is given #
if [ $# -lt 1 ]
then
        help
        error "Usage : $0 command"
        exit 1
fi

case "$1" in
# Display help
help) 
    help
    ;;
# Init Local environment
initLocal) log "Initing Local Command received"
    initLocal
    ;;
# Destroy Local environment
destroyLocal) log "Destroy Local Command received"
    destroyLocal
    ;;
# Init S3 environment
initS3) log "Initing S3 Command received"
    initS3
    ;;
# Destroy Local environment
destroyS3) log "Destroy S3 Command received"
    destroyS3
    ;;
# Start Vault instance
startVault) log "Start Vault Command received"
    startVaultDocker
    ;;
# Stop Vault instance
stopVault) log "Stop Vault Command received"
    stopVaultDocker
    ;;
# Set Secret
setSecret) 
if [[ -z $2 || -z $3 || -z $4 ]]
    then
      error "You need three additional parms for this command (location, key, secret)"
    else
      setSecret $2 $3 $4
    fi
    ;;
# Get Secret
getSecret) 
    if [[ -z $2 || -z $3 ]]
    then
      error "You need two additional parms for this command (location, key)"
    else
      getSecret $2 $3 
    fi
    ;;
*) error "Invalid option"
    #other things?
   ;;
esac

