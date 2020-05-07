### Add new user to EC2 instance

This repository contains two scripts to run for quickly adding a new user to an AWS EC2 instance who has sudo access and automatically has SSH access.


**Prerequisites:**

- Your own user must already have been created on the target EC2 instance
- Your own user must have root access on the target EC2 instance
- Your own user must have ssh access to the target EC2 instance



**Steps:**

- Clone this repository to use the AddUser.sh script

  ```
  git clone https://github.com/bu-ist/kuali-deployment-overview.git
  cd kuali-deployment-overview
  ```

  ​    

- In order to run the script to add one or more users to one or more EC2 instances, you need the following values:

  - **Your User name:** The name of your own user on the EC2 instance. This user has root access.
  - **Your User key:** The key for your own user to connect to the instance through SSH.
  - **User name(s):** The name of each user you want to create on the EC2 instance.
  - **EC2 address(es):** The TCP IP address for each EC2 instance on which to create the user(s)
        

- Run the script
  EXAMPLES:

  - Create one user (mahichy) on one EC2 instance (10.57.237.84), issuing the command over SSH with your user (wrh) and SSH key (buaws-kuali-rsa).

    ```
    # Replace all but the first (--task) parameters with your own selections
    sh AddUser.sh \
      --task 'makeuser' \
      --instance-ids '10.57.237.84' \
      --username 'mahichy' \
      --ssh-key 'buaws-kuali-rsa' \
      --ssh-user 'wrh'
    ```

    > *NOTE: This script will only look for your key at ~/.ssh - You cannot specify a path to indicate an SSH key that is sitting somewhere else on your file system.*

  - Create multiple users (mahichy, lhuval, dhaywood) on multiple EC2 instances ('10.57.237.84' '10.57.237.85' '10.57.237.36'), issuing the command over SSH with your user (wrh) and SSH key (buaws-kuali-rsa).

    ```
    # Replace all but the first (--task) parameters with your own selections
    sh AddUser.sh \
      --task 'makeuser' \
      --instance-ids '10.57.237.84' '10.57.237.85' '10.57.237.36' \
      --username 'mahichy' 'lhuval' 'dhaywood' \
      --ssh-key 'buaws-kuali-rsa' \
      --ssh-user 'wrh'
    ```

    



