### Overview of Jenkins build/deploy jobs.

The following is a high level description and topology layout for how kuali applications make their way from source code in a github repository to running application within our cloud based infrastructure.

#### <img src="images\jenkins1-halfsize.png" alt="jenkins1"/>

The majority of deployment actions are automated in jenkins as jobs. The best place to start is to cover what happens in the deployments from the jenkins vantage point.

Jenkins is running on an AWS EC2 instance. It exposes a website where users can create, edit, and view jobs for the building and deploying of applications

Each kuali module (ie: cor-main, research-dashboard, kc, etc.) undergoes 5 main steps to go from raw code in a github repository to application running in a docker container hosted on one or more EC2 instances in our AWS server environment:

#### Steps:

1. <u>**Github Preparation:**</u>
   $$
   Pull, merge, push.
   $$
   Before the remaining 4 steps can occur, the specific version of the application code we want to deploy for a release needs to be acquired from the [kualico github account](https://github.com/kualico/) repository and merged into the corresponding github repository hosted within the [bu-ist github account](https://github.com/bu-ist?q=&type=&language=).

   ```
   # Example transfer of code from the kualico cor-main repo to the bu-ist cor-main repo.
   # The merged code in this example is for the January 2020 release, 2001.0040 as a tag.
   
   # If first time download:
   git clone https://github.com/bu-ist/kuali-core-main.git
   cd kuali-core-main
   git remote add kualico https://github.com/KualiCo/cor-main.git
   
   # Else if the cor-main repo exists locally:
   cd kuali-core-main
   git checkout master
   git pull --tags origin 
   
   # Do these steps in both cases.
   git fetch kualico master
   git checkout -b upstream FETCH_HEAD
   git log --oneline -n 50
   # Identify the commit [abc123] from the log output you want to merge into the master branch
   git checkout master
   git merge abc123
   # Handle any merge conflicts and commit the merged result and then tag that commit:
   git tag 2001.0040 HEAD
   git push --tags origin master:master
   git push --tags origin upstream:master
   ```

   

   A [helper script](ReleasePrepHelperScript.md) has been prepared to automate much of the actions detailed above (all except merging). 
   If you were doing this manually this is how the branches are arranged.

   ![alt text](https://github.com/bu-ist/kuali-deployment-overview/blob/master/images/GitRepos.jpg "Git Repos and Branches")
   
      
   
2. **<u>Configuration Preparation:</u>**
   
   Some configuration files cannot be "baked" into docker images because:
   
- They contain sensitive info like database passwords, keys, etc.
   - They contain environment-specific information too unweildy to inject into a docker container as an environment variable provided with the docker run command.
   
   All such configuration files are kept in an s3 [bucket: kuali-research-ec2-setup](https://s3.console.aws.amazon.com/s3/buckets/kuali-research-ec2-setup/?region=us-east-1)
   
   A typical release may include new features that need configuration modifications to these files.
   
   ```
   # Acquire all configs for every environment:
   cd ~ && mkdir s3 && cd s3
   for env in sb ci qa stg prod ; do \
     aws s3 cp --recursive s3://kuali-research-ec2-setup/$env ./$env; \
   done
   
   # Show a diff of two files:
   diff -y --color=always stg/kuali/main/config/kc-config.xml prod/kuali/main/config/kc-config.xml
   
   # Make a change to the prod kc-config file
   echo "Making changes"
   
   # Upload to s3 your changes to the prod kc-config file
   aws s3 cp ~/s3/prod/kuali/main/config/kc-config.xml s3://kuali-research-ec2-setup/prod/kuali/main/config/kc-config.xml
   
   # Download from s3 your changes
   ssh yourself@ec2-ip -i path/to/your/ssh/key "sudo aws s3 cp s3://kuali-research-ec2-setup/prod/kuali/main/config/kc-config.xml /opt/kuali/main/config/kc-config.xml"
   ```
   
   
   
3. **Jenkins Job 1**
   Pull helper scripts to from github to aid in running the remaining jenkins jobs.
   [View description and diagram](Jenkins1.md) 
       

4. **Jenkins Job 2**
   Build the docker image for a specific module and environment.
   [View description and diagram](Jenkins2.md)
       

5. **Jenkins Job 3**
   Push the built docker image to our ECR docker registry
   [View description and diagram](Jenkins3.md)
       

6. **Jenkins Job 4**
   Issue commands using the AWS system manager to the EC2 instance(s) to acquire the new docker image and restart their containers against the new release it contains.
   [View description and diagram](Jenkins4.md)




This basic flow is depicted here.

<img src="images\deployment1.png" alt="deployment1"/>


