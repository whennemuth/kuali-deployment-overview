### Transfer a Docker image from one registry to another

The expected use case for this occurs when kualico issues a newer docker image for one of their modules (like research-pdf) that we are interested in including in an upcoming release.
We would like the new docker image to be available in our own AWS elastic container registry.

There is a [jenkins job](http://10.57.236.6:8080/view/Kuali-Pdf/job/kuali-pdf-1-update-docker-image/) that will do this for you. You must be on the BU network or connected to the VPN to be able to access Jenkins.

But if you prefer the manual approach, the script below is an example of doing this in the command line:

```
#!/bin/bash

# Assign input to variables. kc_image and bu_image are both optional, but have default values.
password="$1"
version="$2"
kc_image=${3:-"kuali/research-pdf"}
bu_image=${4:-"730096353738.dkr.ecr.us-east-1.amazonaws.com/research-pdf"}

# Authenticate and then retrieve the specified image from dockerhub
echo "$password" | docker login --username buistuser --password-stdin
docker pull ${kc_image}:${version}

# Duplicate the downloaded image, tagging it as the ecr target.
docker tag ${kc_image}:${version} ${bu_image}:${version}

# Prepare for login to the ecr by obtaining the docker command w/token.
# Assumes the credentials you are using with the aws cli have a role that includes ecr login.
evalstr="$(aws ecr get-login --no-include-email)"

# Execute the login
eval "$evalstr"

# Push the image to the ecr
docker push ${bu_image}:${version}
```

