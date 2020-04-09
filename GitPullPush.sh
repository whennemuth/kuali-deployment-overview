#!/bin/bash

# Use this script to automate pulling new github content from upstream kualico repositories and pushing
# this content to each corresponding upstream branch in the boston university github repository.
# The sequence of actions for each repository is
#   1) Clone the repository from the boston university github account
#   2) Checkout the upstream branch (from kualico) if one is indicated.
#   3) Pull all commits from the upstream kualico repository to the upstream branch
#   4) Push the local upstream repository to the boston university github copy of the upstream branch
# In most cases the "upstream" branch and the custom branch (ie: bu-master) are the same branch
# because the module is not one we are customizing. If the module is being customized, the custom branch
# will be left checked out and ready for further steps to be performed manually involving merging a
# selected commit from the upstream branch into it, tagging and pushing to the bu github account.

pullPush() {
  if [ -z "$1" ] ; then
    pullPush kc kc-rice kc-api kc-s2sgen schemaspy cor-main kuali-ui cor-common formbot \
    cor-formbot-gadgets fluffle research-portal research-pdf
  else
      for gitrepo in $@ ; do
        case $gitrepo in
            kc)
                pullPushOne 'kc'                  'kuali-research'            'bu-master' 'master' ;;
            kc-rice)
                pullPushOne 'kc-rice'             'kuali-kc-rice'             'master'    'master' ;;
            kc-api)
                pullPushOne 'kc-api'              'kuali-kc-api'              'master'    'master' ;;
            kc-s2sgen)
                pullPushOne 'kc-s2sgen'           'kuali-kc-s2sgen'           'master'    'master' ;;
            schemaspy)
                pullPushOne 'schemaspy'           'kuali-schemaspy'           'master'    'master' ;;
            cor-main)
                pullPushOne 'cor-main'            'kuali-core-main'           'master'    'upstream' ;;
            kuali-ui)
                pullPushOne 'kuali-ui'            'kuali-ui'                  'master'    'upstream' ;;    
            cor-common)
                pullPushOne 'cor-common'          'kuali-core-common'         'master'    'master' ;;
            formbot)
                pullPushOne 'formbot'             'kuali-formbot'             'master'    'master' ;;
            cor-common-gadgets)
                pullPushOne 'cor-formbot-gadgets' 'kuali-cor-formbot-gadgets' 'master'    'master' ;;
            fluffle)
                pullPushOne 'fluffle'             'kuali-fluffle'             'master'    'master' ;;
            research-portal)
                pullPushOne 'research-portal'     'kuali-research-portal'     'master'    'upstream' ;;
            research-pdf)
                pullPushOne 'research-pdf'        'kuali-research-pdf'        'master'    'master' ;;
            research-coi)
                pullPushOne 'research-coi'        'kuali-research-coi'        'master'    'upstream' ;;
        esac
      done
  fi
}

pullPushOne() {
    local kualirepo="$1"
    local burepo="$2"
    local bumaster="$3"
    local upstream="$4"

    local buUrl="https://$gitUser:$encodedPassword@github.com/bu-ist/${burepo}.git"
    local kualiUrl="https://$gitUser:$encodedPassword@github.com/KualiCo/${kualirepo}.git"

    if [ ! -d $kualirepo ] ; then
      git clone -o bu $buUrl $kualirepo
      if [ $? -eq 0 ] ; then
        cd $kualirepo
        git remote add kualico $kualiUrl
        if checkoutBranch $upstream ; then
            if pullUpstream $upstream ; then
            pushUpstreamToBU $upstream
            fi
        fi
        cd $rootdir
      else
        echo "ERROR: problem cloning $buUrl"
      fi
    else
      cd $kualirepo
      if [ -z "$(git remote | grep '^bu$')" ] ; then
        git remote add bu $buUrl
      fi
      if [ -z "$(git remote | grep '^kualico$')" ] ; then
        git remote add kualico $kualiUrl
      fi

      if checkoutBranch $upstream ; then
        if pullUpstream $upstream ; then
          pushUpstreamToBU $upstream
          if checkoutBranch $bumaster ; then
            if [ "$bumaster" != "$upstream" ] ; then
              git fetch bu $bumaster
            fi
          fi
        fi        
      fi
      cd $rootdir
    fi

    if [ "$bumaster" != "$upstream" ] ; then
      mergable="$mergable $kualirepo"
    fi
}

checkoutBranch() {
    local branch="$1"
    local atBranch="$(git branch --points-at HEAD | sed 's/\*[[:space:]]//g')"
    local success='true'
    if [ "$branch" != "$atBranch" ] ; then
      local cmd="git checkout $branch"
      echo "$cmd" && eval "$cmd"
      [ $? -gt 0 ] && success='false' && echo "Error checking out the $branch branch!"
    fi
    [ $success == "true" ] && true || false
}

pullUpstream() {
  local upstream="$1"
  local success='true'
  local cmd="git pull --tags kualico master:$upstream"
  echo "$cmd" && eval "$cmd"
  [ $? -gt 0 ] && success='false' && echo "Error pulling from upstream!"
  [ $success == "true" ] && true || false
}

pushUpstreamToBU() {
  local cmd="git push --tags bu $upstream:$upstream"
  echo "$cmd" # && eval "$cmd" 
  [ $? -gt 0 ] && echo "Error pushing kualico upstream branch to bu upstream branch!"
}

rootdir="$(pwd)"
gitUser="$1"
shift
gitPassword="$1"
shift
repos="$@"
mergable=""

[ -z "$gitPassword" ] && echo "You forgot to provide the git password!" && exit 1

encodedPassword="$(echo -ne $gitPassword | xxd -plain | tr -d '\n' | sed 's/\(..\)/%\1/g')"

pullPush "$repos"

if [ -n "$mergable" ] ; then
  printf "\n\nThe following repositories have a custom branch (ie: 'bu-master')\n
and need to have the appropriate commit from the kualico upstream merged into them:\n"
  for m in $mergable ; do
    echo "    $m"
  done
fi
