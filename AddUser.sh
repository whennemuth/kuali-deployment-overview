#!/bin/bash

instanceIds=""
usernames=""

# Generate a public/private key pair and return the content of the public key.
generateKey() {
  local $username=$1
  [ -z "$username" ] && echo "No username parameter provided. Cancelling!" && exit 1
  cd ~/.ssh
  keyname=${username}_rsa
  ssh-keygen -b 2048 -t rsa -f $keyname -q -N "" -C ""
  cd -
}

createUserOnEC2() {
  [ -z "$usernames" ] && echo "No --usernames parameter provided. Cancelling!" && exit 1
  [ -z "$instanceIds" ] && echo "No --instance-ids parameter provided. Cancelling!" && exit 1
  [ -z "$sshuser" ] && echo "No --ssh-user parameter provided. Cancelling!" && exit 1
  [ -z "$sshkey" ] && echo "No --ssh-key parameter provided. Cancelling!" && exit 1
  for username in $usernames ; do
    generateKey $username
    local pubkey="$(cat ~/.ssh/${keyname}.pub)"
    # Trim off any trailing whitespace
    pubkey="$(echo "$pubkey" | sed 's/ *$//g')"
    for ipaddress in $instanceIds ; do
      echo "Dropping addUser.sh to /tmp directory on $ipaddress for $username ..."
      ssh -i ~/.ssh/$sshkey $sshuser@$ipaddress "bash -s \"$username\" \"$pubkey\"" < UserAdd.sh
      echo "Executing /tmp/addUser.sh on $ipaddress for $username..."
      ssh -i ~/.ssh/$sshkey $sshuser@$ipaddress "sudo bash /tmp/addUser.sh"
    done;
  done;
}

# Set the variables global to the shell from here on that were provided as args.
parseargs() {
  local posargs=""

  while (( "$#" )); do
    case "$1" in
      -t|--task)
        parsingInstanceIds=""
        parsingUsernames=""
        eval "$(parseValue $1 "$2" 'task')" ;;
      -i|--instance-ids)
        parsingInstanceIds="true"
        parsingUsernames=""
        eval "$(parseValue $1 "$2" 'instanceIds')" ;;
      -u|--usernames)
        parsingInstanceIds=""
        parsingUsernames="true"
        eval "$(parseValue $1 "$2" 'usernames')" ;;
      -s|--ssh-key)
        parsingInstanceIds=""
        parsingUsernames=""
        eval "$(parseValue $1 "$2" 'sshkey')" ;;
      -s|--ssh-user)
        parsingInstanceIds=""
        parsingUsernames=""
        eval "$(parseValue $1 "$2" 'sshuser')" ;;
      -*|--*=) # unsupported flags
        echo "Error: Unsupported flag $1" >&2
        printusage
        exit 1
        ;;
      *) # preserve positional arguments (should not be any more than the leading command, but collect then anyway) 
        if [ -n "$parsingInstanceIds" ] ; then
          instanceIds="$instanceIds $1"
        fi
        if [ -n "$parsingUsernames" ] ; then
          usernames="$usernames $1"
        fi
        posargs="$posargs $1"
        shift
        ;;
    esac
  done

  # set positional arguments in their proper place
  eval set -- "$posargs"
}

parseValue() {
  local cmd=""

  # Blank out prior values:
  [ "$#" == '3' ] && eval "$3="
  [ "$#" == '2' ] && eval "$2="

  if [ -n "$2" ] && [ ${2:0:1} == '-' ] ; then
    # Named arg found with no value (it is followed by another named arg)
    echo "echo 'ERROR! $1 has no value!' && exit 1"
    exit 1
  elif [ -n "$2" ] && [ "$#" == "3" ] ; then
    # Named arg found with a value
    cmd="$3=\"$2\" && shift 2"
  elif [ -n "$2" ] ; then
    # Named arg found with no value
    echo "echo 'ERROR! $1 has no value!' && exit 1"
    exit 1
  fi

  echo "$cmd"
}

parseargs "$@"

case ${task,,} in
  makekey)
    generateKey ;;
  makeuser)
    createUserOnEC2 ;;      
esac