### Release prep github helper script

A [helper script](gitPullPush.sh) has been prepared to automate much of the actions detailed in [The main jenkins readme file](Jenkins.md) (all except merging). Use this script to automate pulling new github content from upstream kualico repositories and pushing this content to each corresponding upstream branch in the boston university github repository. The sequence of actions for each repository is:

1. Clone the repository from the boston university github account
2. Checkout the upstream branch (from kualico) if one is indicated.
3. Pull all commits from the upstream kualico repository to the upstream branch
4. Push the local upstream repository to the Boston University github copy of the upstream branch

![](images\GitPullPush.png)

In most cases the "upstream" branch and the custom branch (ie: bu-master) are the same branch because the module is not one we are customizing. If the module is being customized, the custom branch will be left checked out and ready for further steps to be performed manually involving merging a selected commit from the upstream branch into it, tagging and pushing to the bu github account.

```
# You are working locally or have shelled into an EC2 instance.

# Acquire GitPullPush.sh from this git repository
# You can cut and paste the old-fashioned way, or you could use the personal access token
# that belongs to the bu-ist-user github user. You can find this token under passwords in
# 1Password entitled "Personal Access Token for bu-ist-user"
cd ~
mkdir /gitwork
cd gitwork
curl \
  -H "Authorization: token ${token}" \
  -L https://api.github.com/repos/bu-ist/kuali-deployment-overview/contents/GitPullPush.sh \
  | jq '.content' \
  | sed 's/\\n//g' \
  | sed 's/"//g' \
  | base64 --decode \
  > GitPullPush.sh
  
  # Now you will need the github password for bu-ist-user. This is also to be found in 
  # 1Password, but in the logins section.
  
  # To process a single repository (cor-common), call as follows:
  sh GitPullPush.sh bu-ist-user "${password}" cor-common
  
  # To process multiple repositories (cor-common, kuali-ui, fluffle), call as follows:
  sh GitPullPush.sh bu-ist-user "${password}" cor-common, kuali-ui, fluffle
  
  # To process all repositories, omit all but the user and password:
  sh GitPullPush.sh bu-ist-user "${password}"
```

