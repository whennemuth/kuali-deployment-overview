#!/bin/bash

prune() {

  logState "Initial"

  [ -n "$images" ] && pruneImages

  [ -n "$volumes" ] && pruneVolumes

  [ -n "$tomcat" ] && pruneTomcatLogs

  [ -n "$apache" ] && pruneApacheLogs

  logState "Pruned"
}

setCrontab() {
  local crondir="/etc/cron.d"
  [ ! -d $crondir ] && crondir="/root"
  local crontabfile="$crondir/kuali-prune-crontab"
  local args=""
  [ -n "$images" ]  && args="$args --images"
  [ -n "$volumes" ] && args="$args --volumes"
  [ -n "$tomcat" ]  && args="$args --tomcat"
  [ -n "$apache" ]  && args="$args --apache"
  [ -n "$debug" ]   && args="$args --debug"
  args="$args --logfile $logfile"

  local scriptdir="$(dirname "$0")"
  if [ "${scriptdir:0:1}" == "." ] ; then
    # The script was not called by absolute path
    scriptdir="$(pwd)"
  fi

  cat <<EOF > $crontabfile
SHELL=/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin
MAILTO=root

# Run disk cleanup to free up space taken by kuali apps.

$crontab root sh $scriptdir/DiskCleanup.sh $args
EOF

  if [ -d "/etc/cron.d" ] ; then
    # The following level of ownership/auth should be set this way by default, but make sure...
    chmod 644 $crontabfile
    chown root:root $crontabfile
  else
    chmod 755 $crontabfile
    crontab -u root $crontabfile
    crontab -l -u root
  fi
  echo "Set crontab: $crontabfile"
  echo ""
  cat $crontabfile
}

logState() {
  local msg="$1 disk space"
  logHeading "$msg"
  if [ -n "$debug" ] ; then
    echo "DEBUG: $msg..."
  else
    df -h /
    echo " "
    docker system df
    echo " "
    du -x -d1 -h / | sort -h -r
  fi
}

logHeading() {
  local line="********************************************"
  printf "\n$line\n"
  printf "          $1"
  printf "\n$line\n"
}

pruneImages() {
  logHeading "Pruning docker images..."
  if [ -n "$debug" ] ; then
    echo "DEBUG: Pruning docker images..."
  else
    # IMPORTANT! This assumes all images you want to keep are connected to containers
    # that are currently running. We start by deleting all non-running containers.
    for stoppedContainer in $(docker ps --filter status=exited -q) ; do
        docker rm -f $stoppedContainer;
    done
    docker image prune -a -f
  fi
}

pruneVolumes() {
  logHeading "Pruning docker volumes..."
  if [ -n "$debug" ] ; then
    echo "DEBUG: logging disk space..."
  else
    docker volume prune -f
  fi
}

pruneTomcatLogs() {
  local logdir="/var/log/tomcat"
  logHeading "Pruning tomcat logs..."
  if [ -n "$debug" ] ; then
    echo "DEBUG: Pruning tomcat logs..."
  elif [ ! -d $logdir ] ; then
    echo "Tomcat directory does not exist: $logdir"
    return 0
  else
    days=$1
    find $logdir -type f -mtime +${days} -exec rm -f {} \;
  fi
}

pruneApacheLogs() {
  local logdir="/var/log/httpd"
  logHeading "Pruning apache logs..."
  if [ -n "$debug" ] ; then
    echo "DEBUG: Pruning apache logs..."
  elif [ ! -d $logdir ] ; then
    echo "Tomcat directory does not exist: $logdir"
    return 0
  else
    # Stop apache docker container
    docker stop apache-shibboleth
    # Remove any existing archives
    rm -f $logdir/archive-*
    # Archive all the current logs
    tar -czvf $logdir/archive-$(date '+%b-%d-%Y-%T').tar.gz $logdir
    # Delete all the current logs now that they are archived
    for log in $(ls -1 $logdir | grep -v 'archive') ; do
        rm -f $logdir/$log
    done 
    # Restart apache docker container
    docker start apache-shibboleth
  fi
}

# Set the variables global to the shell from here on that were provided as args.
parseargs() {
  local posargs=""

  while (( "$#" )); do
    case "$1" in
      -a|--all)
        images="true"
        volumes="true"
        tomcat="true"
        apache="true" 
        shift ;;
      -i|--images)
        images="true" 
        shift ;;
      -v|--volumes)
       volumes="true" 
        shift ;;
      -t|--tomcat)
        tomcat="true" 
        shift ;;
      -h|--httpd|--apache)
        apache="true" 
        shift ;;
      -d|--debug)
        debug="true" 
        shift ;;
      --LOGGING)
        # Private variable this script uses to call itself for file logging.
        LOGGING="true" 
        shift ;;
      -l|--logfile)
        eval "$(parseValue $1 "$2" 'logfile')" ;;
      -c|--crontab)
        eval "$(parseValue $1 "$2" 'crontab')" ;;
      -*|--*=) # unsupported flags
        echo "Error: Unsupported flag $1" >&2
        printusage
        exit 1
        ;;
      *) # preserve positional arguments (should not be any more than the leading command, but collect then anyway) 
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

  if [ -n "$2" ] && [ "${2:0:1}" == '-' ] ; then
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

# Attempt to create a new log file at the specified location and swallow 
# the error if it cannot be created, but return true or false instead.
newlog() {
  eval "printf "" > "$logfile"" > /dev/null 2>&1
  [ -f "$logfile" ] && true || false
}

# 1) Use the explicit path provided for a log file
# 2) Otherwise use the default value /tmp/prune.log
# 3) Otherwise create prune.log in the current directory.
setLogFile() {
  default="/tmp/prune.log"
  if [ -z "$logfile" ] ; then
    logfile=$default
    newlog
    setLogFile
  elif [ -f $logfile ] ; then
    echo "Using logfile: $logfile"
  elif [ ! -f $logfile ] && [ $logfile == "$default" ] ; then
    logfile="$(pwd)/prune.log"
    newlog
    setLogFile
  elif [ ! -f $logfile ] && [ $logfile != "$default" ] ; then
    if ! newlog ; then
      logfile="$default"
      newlog
    fi
    setLogFile
  else
    newlog
    setLogFile
  fi
}

parseargs "$@"

if [ -n "$LOGGING" ] ; then
  shift
  if [ -n "$crontab" ] ; then
    setCrontab $@
  else
    prune
  fi
else
  setLogFile
  if [ -f "$logfile" ] ; then
    # NOTE: As long as the crontab calls DiskCleanup.sh with an absolute path, $0 will return that absolute path.
    # $(pwd) will return "/usr/bin", where DiskCleanup.sh is NOT located, so don't use it.
    scriptdir="$(dirname "$0")"
    if [ "${scriptdir:0:1}" == "." ] ; then
      # The script was not called by absolute path
      scriptdir="$(pwd)"
    fi
    sh $scriptdir/DiskCleanup.sh "--LOGGING" "$@" "--logfile" $logfile 2>&1 | tee -a "$logfile"
    # sh $scriptdir/DiskCleanup.sh "--LOGGING" "$@" "--logfile" $logfile |& tee -a $logfile
  else
    echo "ERROR! Cannot create log file: $logfile"
  fi
fi
