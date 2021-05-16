
# The Local Vault Installed on your junk project!
#### TL;DR:
If you clone this down to a directory at ~/secrets/, you can do the following in your .zshrc or .bashrc files:
```
export AWS_ACCESS_KEY_ID=$(pushd ~/secrets > /dev/null; ./vault.sh getSecret aws_access_key_id; popd > /dev/null)
```
Then, open a new terminal, and:
```
echo $AWS_ACCESS_KEY_ID
```
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
./vault.sh setSecret key value
```

* Get secrets:
```
./vault.sh getSecret key
```
