### Jenkins Job 2

#### Build the application into a Docker image.

This process has the following steps:

1. Use the helper scripts pulled in job 1 to download github keys and configuration files from our AWS S3 bucket (kuali-research-ec2-setup)
2. Invoke the helper script function that triggers the docker build process
3. The Dockerfile has initial instructions to download git deploy keys from the same S3 bucket into the image as it's being built. These keys will allow access to pull source code from various github repositories. 
4. The Dockerfile has an instruction to pull the same helper scripts from github. These scripts have functionality for building the application from it's source code as well as dependency modules from their source code.
5. The Dockerfile has an instruction to pull the source code of the main application from github.
6. The Dockerfile has an instruction to inspect the dependency management file (ie: pom.xml, package.json, etc.) from the the source code obtained in the previous step to determine the correct versions of dependencies and pull their source code from the corresponding point in history from their respective github repositories.
7. The Dockerfile has an instruction to build and install the dependencies. For nodeJs applications, this involves installing the built artifacts in a npm registry running locally inside the current layer of the forming docker image. 
8. The Dockerfile has an instruction to build the primary module of the application now that the dependencies are installed and available. For a java application this happens as part of a single maven command to build the entire application, main module and dependencies all, making it part of the prior step.
9. The Dockerfile instructions are complete and the new image with specified tag is added to the local docker repository.

​                                                           [<<    Previous job](Jenkins1.md)                      [Next job   >>](images/Jenkins3.md)



<img src="images\deployment3.png" alt="jenkins2"/>