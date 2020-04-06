### Overview of Kuali deployments in the BU AWS cloud environment.

This repository comprises a rough knowledge transfer and documentation point for building and deployment of of our kuali applications and their hosting in our AWS cloud environments. Also some standard linux and git/github actions are included.

#### Topics:

- [Jenkins](Jenkins.md)
  Covers the basic organization and sequencing of jobs in jenkins. 
  Overviews the building and deploying kuali modules with Jenkins Jobs.
- Various admin topics
  - [Github access and shortcuts](GitAccess.md)
    Directions for establishing ssh access to github repositories and aliasing access for quick connections.
  - [Create EC2 users](CreateEC2Users.md)
    Directions for how to create users on a linux-based EC2 instance with an SSH key for secure access.
  - [Renew SSL Certificates](RenewCertificates.md)
    Details how to renew expiring SSL/TLS certificates in AWS.
  - [Resize EBS Volume for an EC2 Instance](ResizeEBSVolume.md)
    Details how to increase the available disk space for an EC2 instance that needs more room.
  - [Update Docker Registry](UpdateDockerRegistry.md)
    Details how to download docker images from kualico and upload them to our ECR
  - [Elastic Search for Kuali](https://github.com/bu-ist/kuali-cloudformation/blob/master/related/es_for_kuali.md)
    Details the cloud formation setup and configuration of the elastic search cluster for the search feature used by the research-portal and kc applications.
  - [EC2 Access Management](EC2AccessManagement.md)
    Details how the EC2 server application hosts and the Jenkins EC2 server have been given access to certain AWS resources through command line interface (cli) calls.
  - [EC2 Disk Cleanup](DiskCleanup.md)
    Details how to reclaim disk space on our EC2 application hosts due to logging and docker activity.

