### Add new user to EC2 instance

The following is a script to run for quickly adding a new user to an AWS EC2 instance who has sudo access and automatically has SSH access.

```
#!/bin/bash

AddUser() {
  local username=$1
  sudo su root

  if [ ! -d /home/$username ] ; then
    useradd -d /home/$username -u 1000 -g docker -m -s /bin/bash $username
    usermod -a -G sudo $username
  fi
  
  if [ ! -d /home/$username/.ssh ] ; then
    mkdir -m 700 /home/$username/.ssh
    cd /home/$username/.ssh        
    ssh-keygen -b 2048 -t rsa -f ${username}_rsa -q -N ""
    touch authorized_keys
    chmod 600 authorized_keys
    cat ${username}_rsa.pub >> authorized_keys
    rm ${username}_rsa.pub
    # NOTE: Save the private key locally before you delete it.
    # rm -f ${username}_rsa
    chown -R $username:docker /home/$username/.ssh
  fi
}
```

