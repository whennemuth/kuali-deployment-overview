### Overview of Kuali deployments in the BU AWS cloud environment.

The following is a high level description and topology layout for how kuali applications make their way from source code in a github repository to running application within our cloud based infrastructure.

#### <img src="images\jenkins1-halfsize.png" alt="jenkins1"/>

The majority of deployment actions are automated in jenkins as jobs. The best place to start is to cover what happens in the deployments from the jenkins vantage point.

Each kuali module (ie: cor-main, research-dashboard, kc, etc.) undergoes 4 main steps to go from raw code in a github repository to application running in a docker container hosted on one or more EC2 instances in our AWS server environment.

#### <u>**Github Preparation:**</u>

Before these 4 steps can occur, the specific version of the application code we want to deploy for a release needs to be acquired from the [kualico github account](https://github.com/kualico/) repository and merged into the corresponding github repository hosted within the [bu-ist github account](https://github.com/bu-ist?q=&type=&language=).

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



#### **<u>Overview of Jenkins deployment:</u>**

At a high level, there are 3 main components to the deployment of a module.

1. **Github**
   The github repository is prepared with the new release for the module in our bu-ist account.
2. **Jenkins**
   Jenkins is running on an AWS EC2 instance. It exposes a website where users can create, edit, and view jobs for the building and deploying of applications. 
3. **Application Servers**
   The target application servers receive the new build artifacts from Jenkins and run them as a new release.


This basic flow is depicted here.

<img src="images\deployment1.png" alt="deployment1"/>



#### **<u>Overview of Jenkins deployment:</u>**



A closer look at a Jenkins build and/or deployment looks like this:

1. Pull the build scripts. 
   Primary among these is the docker build context, which a directory of files including the Dockerfile, and configuration files that are copied into the docker image as it is being built. Also included are bash script files that provide helper scripts for the build process.

   <img src="images\deployment2.png" alt="deployment2"/>

2. Build the Docker image.

   