### Resize the EBS volume for an EC2 Instance

If an EC2 instance is running out of disk space, there are many things you might do to clean up to free up some of that used space. Alternatively, you can simply resize the disk to a larger size.
Below is an example of having done this using the AWS CLI.

```
# Stop the EC2 instance
aws ec2 stop-instances --instance-ids i-0f0f920848adfa906

# Detach the existing volume from the EC2 instance
aws ec2 detach-volume --volume-id vol-0de1b76e3662237f5

# Create a snapshot of the detached volume
aws ec2 create-snapshot --volume-id vol-0de1b76e3662237f5 --description "Backup for buaws-kuali-rsa-warren"

# Create the new larger volume providing the id of the snapshot.
aws ec2 create-volume --size 128 --snapshot-id [???] --region us-east-1 --availability-zone us-east-1c --volume-type gp2

# Attach the new larger volume to the EC2 instance
aws ec2 attach-volume --volume-id [???] --instance-id i-0f0f920848adfa906 --device /dev/xvda

# Start the EC2 instance
aws ec2 start-instances --instance-ids i-0f0f920848adfa906

NOTE: You may get a warning about attach-volume command complains about bad device name when run from Windows. You can ignore this warning
```

