#!/bin/bash

if [ -z $* ]
then
echo "No options found! Please start script with -d (deploy), -e (erase) keys"
exit 1
fi

# export variable GP (GCP project name)
TF_VAR_GP=terraform64
export TF_VAR_GP

# export region value 
TF_VAR_REG=europe-west1
export TF_VAR_REG

# export image value
TF_VAR_IMG=gcp-centos7-apache
export TF_VAR_IMG

# export forwarding rule name
TF_VAR_LB=lb
export TF_VAR_LB

# https://cloud.google.com/docs/authentication/production#obtaining_and_providing_service_account_credentials_manually
GOOGLE_APPLICATION_CREDENTIALS=$(pwd)/auth/account.json
export GOOGLE_APPLICATION_CREDENTIALS=$(pwd)/auth/account.json

# activate service account with JSON creds file
gcloud auth activate-service-account --key-file=${GOOGLE_APPLICATION_CREDENTIALS}

# show authorized account (to check the correct account has been choosed)
gcloud auth list

while getopts "de" opt
do
case $opt in
d) gsutil mb -p ${TF_VAR_GP} -s coldline -l ${TF_VAR_REG} gs://${TF_VAR_GP} # create backend bucket for state saving
   cd   terraform
        terraform init                					    # terraform's provider initialization (GCP driver in this example)
   gsutil versioning set on gs://${TF_VAR_GP}				    # set versioning on the bucket
      terraform plan							    # ad-hoc check for resources creation (plan)
   cd ../packer
         packer validate template.json					    # packer template syntax validation
         packer inspect template.json
         packer build template.json                  			    # image building
   cd ../terraform 
         terraform apply -auto-approve					    # apply changes to GCP infra with terraform
   cd ../ansible
         ansible-playbook deploy.yml 
   LBIP=$(gcloud compute forwarding-rules describe $TF_VAR_LB --region=$TF_VAR_REG | sed '1!D' | awk '{print $2}')
   echo "Enjoy the result with next IP: "$LBIP;;
e) cd ./terraform && terraform destroy -auto-approve;;
*) echo "No reasonable options found!";;
esac
done
