### Use a github deploy key to access a github repository

Each kuali module exists in github with a deploy key. The deploy key can be used to perform git actions, like pushing and pulling changes where write access is needed. This is an alternative to adding write privileges to your github user for the specific repository, and also eliminates the need to type in a user and password. It is also useful for automation where a process is accessing github (not a person).

Save the following content off to a file ~/gitlogins.sh

```
#!/bin/bash

cat <<EOF >> ~/.bashrc

git_ssh(){
  # \$1 = path of local git repo
  # \$2 = name of ssh private key (assumes it exists at ~/.ssh/)
  # \$3 = name of the git remote
  # \$4 = name of the git repository
  eval "ssh-agent -k"
  cd \$1
  eval \`ssh-agent -s\`
  ssh-add ~/.ssh/\$2
  ssh -T git@github.com
  if [ -z "\$(git remote | grep -P ^\$3\$)" ] ; then
    git remote add \$3 git@github.com:\$4
  fi
}

# Below are examples. Modify the arguments to reflect your own repo paths, keynames, etc.
alias gitdocker='git_ssh \
  /path/to/repo/for/kuali-research-docker \
  bu_github_id_docker_rsa \
  github \
  bu-ist/kuali-research-docker.git'

alias gitkc='git_ssh \
  /c/whennemuth/kuali-research \
  bu_github_id_kc_rsa \
  github \
  bu-ist/kuali-research.git'

alias gitcore='git_ssh \
  /path/to/repo/for/kuali-research-core \
  bu_github_id_core_rsa \
  github \
  bu-ist/kuali-research-core.git'

# etc...
EOF
```



Modify the "alias" entries so that the arguments to reflect your own repo paths, keynames, etc.
Next execute the script you just saved and as follows:

```
sh ~/.gitlogins.sh
```

When run this script has added content to your ~/.bashrc file and the aliases will be available any bash shell you open. For the current shell, you can accomplish this as follows:

```
source ~/.bashrc
```

Now, any time you want to push or pull to any repo you've defined in ~/.bashrc, you need only type the name of the alias. For example, to push changes to the kuali-research repository, do the following:

```
gitkc
git pull github master.
# Add a file
echo "This is a test" > test.txt
git add test.txt
git commit -m "Adding test.txt to repo"
git push github master
```

