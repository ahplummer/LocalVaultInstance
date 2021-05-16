
## Prereqs
* Docker installed
* Vault cli installed `brew install vault`
* AWS cli installed

## What this does

1. Runs full version of Vault inside of docker.
2. Can leverage File store backing (on your machine).
3. Can leverage AWS S3 backing (with appropriate credentials).

## Instantiation Usage
* Instantiate Local Vault backing:
Note: this will destroy anything you have already inited.
```
./vault.sh initLocal
```
* Destroy Local Vault backing:
```
./vault.sh destroyLocal
```
* Instantiate S3 Vault backing:
Note: this will destroy anything you have already inited.
```
./vault.sh initS3
```
* Destroy S3 Vault backing:
```
./vault.sh destroyS3
```

## Start/Stop Usage
* Start previously inited Vault:
```
./vault.sh startVault
```
* Stop previously inited Vault:
```
./vault.sh stopVault
```

## Set/Get Secret Usage
* Set secrets:
```
./vault.sh setSecret thing key value
```
Note: "thing" points to a "group" of things; key is what the secret is known as, value is the secret.

* Get secrets:
```
./vault.sh getSecret thing key
```
Note: "thing" points to a "group" of things;key is what the secret is known as.