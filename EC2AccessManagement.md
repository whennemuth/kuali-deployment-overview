### EC2 Access Management overview

Normally operations against aws resources are allowed for a user by giving that user a role containing policies that grant those actions. The user can then use his credentials to make aws cli calls against those resources.

But, an ec2 instance is not a person and doesn't have an IAM presence as a user.
So, roles are given to ec2 instances through the use of [Instance Profiles](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-ec2_instance-profiles.html).

The following links are to cloud formation templates that have been used to create instance profiles for our ec2 instances. If you wanted to grant an ec2 instance additional access to perform resource actions, you would modify the corresponding cloud formation template and perform a stack update.

The cloud formation template is located in github:

[https://github.com/bu-ist/kuali-cloudformation/blob/master/related/iam_for_kuali.yaml](https://github.com/bu-ist/kuali-cloudformation/blob/master/related/iam_for_kuali.yaml)

The existing cloud formation stack can be view here:

[Kuali-IAM-EC2 Cloud formation stack](https://console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/stackinfo?filteringText=&filteringStatus=active&viewNested=true&hideStacks=false&stackId=arn%3Aaws%3Acloudformation%3Aus-east-1%3A730096353738%3Astack%2FKuali-IAM-EC2%2Fa29d16e0-1b6d-11e9-adb1-126c686965ae)

   

##### Steps to update the stack

You may want to give Jenkins or another EC2 instance extra resource access. 
For example what if you wanted to grant access to invoke lambdas:

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowJenkinsToExampleFunction",
            "Effect": "Allow",
            "Action": "lambda:InvokeFunction",
            "Resource": "arn:aws:lambda:<region>:<123456789012>:function:<example_function>"
        }
    ]
}
```

To do this, you would modify the cloud formation template and perform a stack update.
IMPORTANT: Don't modify the roles directly - use cloud formation so that the stack does not ["drift"](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/detect-drift-stack.html).

```
# Obtain the cloud formation template from github.
# If you do this with the bu-ist-user, you can utilize its personal access token.
# This token can be found as a shared password in 1Password.

git clone https://github.com/bu-ist/kuali-deployment-overview.git
```

