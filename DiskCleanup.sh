#!/bin/bash

prune() {

  logState "Initial"

  [ -n "$images" ] && pruneImages

  [ -n "$volumes" ] && pruneVolumes

  [ -n "$tomcat" ] && pruneTomcatLogs

  [ -n "$apache" ] && pruneApacheLogs

  logState "Pruned"

  [ -n "$email" ] && sendReport
}

setPruningCrontab() {
  local crondir="/etc/cron.d"
  [ ! -d $crondir ] && crondir="/root"
  local crontabfile="$crondir/kuali-prune-crontab"
  local args=""
  [ -n "$images" ]  && args="$args --images"
  [ -n "$volumes" ] && args="$args --volumes"
  [ -n "$tomcat" ]  && args="$args --tomcat"
  [ -n "$apache" ]  && args="$args --apache"
  [ -n "$debug" ]   && args="$args --debug"
  [ -n "$email" ]   && args="$args --email $email"
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

setLowDiskNoficationCrontab() {
  local crondir="/etc/cron.d"
  [ ! -d $crondir ] && crondir="/root"
  local crontabfile="$crondir/kuali-low-disk-crontab"
    
  local scriptdir="$(dirname "$0")"
  if [ "${scriptdir:0:1}" == "." ] ; then
    # The script was not called by absolute path
    scriptdir="$(pwd)"
  fi

  cat <<EOF > $crontabfile
SHELL=/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin
MAILTO=root

# Notify via email if this ec2 instance has over the specified percent disk utilization.

$notifyCrontab root sh $scriptdir/DiskCleanup.sh --notify-disk-percent $notifyPercent --email $email
EOF
}

logState() {
  [ "$skipLogState" == "true" ] && return 0
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
    echo "$logdir directory does not exist: $logdir"
    return 0
  else
    files=$(find $logdir -type f -mtime +${tomcatDeleteLogsAfterDays} | wc -l)
    echo "There are $files files in $logdir that haven't been modified in $tomcatDeleteLogsAfterDays or more days."
    find $logdir -type f -mtime +${tomcatDeleteLogsAfterDays} -exec rm -f {} \;
    echo "$files files deleted."
  fi
}

pruneApacheLogs() {
  local logdir="/var/log/httpd"
  logHeading "Pruning apache logs..."
  if [ -n "$debug" ] ; then
    echo "DEBUG: Pruning apache logs..."
  elif [ ! -d $logdir ] ; then
    echo "$logdir directory does not exist: $logdir"
    return 0
  else
    # Stop apache docker container
    echo "Stopping apache-shibboleth docker container..."
    docker stop apache-shibboleth
    # Remove any existing archives
    echo "Removing existing archive file(s)..."
    rm -f $logdir/archive-*
    # Archive all the current logs
    echo "Archiving log files into single tar file..."
    tar -czvf $logdir/archive-$(date '+%b-%d-%Y-%T').tar.gz $logdir
    # Delete all the current logs now that they are archived
    echo "Deleting log files now that they are archived..."
    for log in $(ls -1 $logdir | grep -v 'archive') ; do
        rm -f $logdir/$log
    done 
    # Restart apache docker container
    echo "Starting apache-shibboleth docker container..."
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
      -s|--skip-log-state)
        skipLogState="true"
        shift ;;
      --LOGGING)
        # Private variable this script uses to call itself for file logging.
        LOGGING="true" 
        shift ;;
      -l|--logfile)
        eval "$(parseValue $1 "$2" 'logfile')" ;;
      -c|--crontab)
        eval "$(parseValue $1 "$2" 'crontab')" ;;
      -e|--email)
        eval "$(parseValue $1 "$2" 'email')" ;;
      --notify-disk-percent)
        eval "$(parseValue $1 "$2" 'notifyPercent')" ;;
      --notify-disk-crontab)
        eval "$(parseValue $1 "$2" 'notifyCrontab')" ;;
      --tomcat-delete-logs-after-days)
        eval "$(parseValue $1 "$2" 'tomcatDeleteLogsAfterDays')" ;;
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

  [ -z "$tomcatDeleteLogsAfterDays" ] && tomcatDeleteLogsAfterDays=30

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

getEnvIdentifier() {
  local instanceId="$(curl http://169.254.169.254/latest/meta-data/instance-id 2> /dev/null)"
  if [ -n "$instanceId" ] ; then
    case "$instanceId" in
      "i-099de1c5407493f9b") echo "Sandbox 1" ;;
      "i-0c2d2ef87e98f2088") echo "Sandbox 2" ;;
      "i-0258a5f2a87ba7972") echo "CI 1" ;;
      "i-0511b83a249cd9fb1") echo "CI 2" ;;
      "i-011ccd29dec6c6d10") echo "QA" ;;
      "i-090d188ea237c8bcf") echo "Staging 1" ;;
      "i-0cb479180574b4ba2") echo "Staging 2" ;;
      "i-0534c4e38e6a24009") echo "Prod 1" ;;
      "i-07d7b5f3e629e89ae") echo "Prod 2" ;;
    esac
  else
    echo "$HOSTNAME"
  fi
}

sendReport() {
  aws ses send-email \
  --from ist-cloud-kuali@bu.edu \
  --to $email \
  --subject "KUALI MAINTENANCE REPORT: Kuali ec2 disk cleanup report for $(getEnvIdentifier)" \
  --text "$(cat $logfile)" \
  --html "<pre>$(cat $logfile)</pre>"
}

# Check that the percent disk utilization is under the specified percentage. 
# If disk utilization breaches this percent threshold, then sent a warning email.
checkLowDisk() {  
  local percentUsed=$(df -h --output=pcent / | sed -n 2p | grep -oP '\d+')
  local instanceId="$(curl http://169.254.169.254/latest/meta-data/instance-id 2> /dev/null)"

  if [ $percentUsed -ge $notifyPercent ] ; then
    local subject="KUALI MAINTENANCE ALERT!: ${notifyPercent}% disk utilization exceeded for kuali ec2 $(getEnvIdentifier)"
    local text=$(cat <<EOF

    EC2 instance: 
      Host: $HOSTNAME
      InstanceId: $instanceId

    Disk Usage:
      Notification percent threshold: $notifyPercent
      Acutal percent used: $percentUsed

    If this is too high, check the crontab schedule for pruning disk space is set.
EOF
) 
    if daySinceLastEmail ; then   
      aws ses send-email \
        --from ist-cloud-kuali@bu.edu \
        --to $email \
        --subject "$subject" \
        --text "$text"

      printf "$(date '+%s')" > /tmp/lastDiskWarningSent
    else
      echo "Disk usage over ${notifyPercent}%, but a notification was sent less than 24 hours ago. Postponing nofitication until a full since the last."
    fi
  fi
}

daySinceLastEmail() {
  local then=$(cat /tmp/lastDiskWarningSent 2> /dev/null)
  local day=$((60 * 60 * 24))
  local elapsed=$day
  if [ -n "$then" ] ; then
    local now=$(date '+%s')
    local elapsed=$(($now - $then))
  fi    
  [ $elapsed -ge $day ] && true || false
}

parseargs "$@"

if [ -n "$LOGGING" ] ; then
  shift
  if [ -n "$crontab" ] ; then
    setPruningCrontab
  else
    prune
  fi
elif [ -n "$notifyPercent" ]  ; then
    if [ -n "$notifyCrontab" ] ; then
      setLowDiskNoficationCrontab
    else
      checkLowDisk
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
    sh $scriptdir/DiskCleanup.sh "--LOGGING" "$@" "--logfile" $logfile 2>&1 | tee "$logfile"
    # sh $scriptdir/DiskCleanup.sh "--LOGGING" "$@" "--logfile" $logfile |& tee $logfile
  else
    echo "ERROR! Cannot create log file: $logfile"
  fi
fi
