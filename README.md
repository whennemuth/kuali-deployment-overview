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

