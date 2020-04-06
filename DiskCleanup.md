### Cleanup disk space on our Kuali application EC2 servers

There are two main culprits for gradual size increase of used disk space on our kuali application servers:

1. **Docker system objects and logs**
   These accumulate in `/var/lib/docker` and the two types of file that can be eliminated or trimmed are: 
        
   
   - **Image data**
     **`/var/lib/docker/devicemapper/devicemapper/data`**
     This is where redhat systems put the image data file for docker. In it are all the images and their layers. Getting rid of unused images will reduce the size of this file. "Unused" means either:
     
     1. **Dangling**
       A dangling image is one that has lost its tag due to a newer image being built and assigned that same tag. Running `docker images` will show these images up as having a tag of `"<none>`".
       You can also query for these types of images with:
     
       ```
       docker images --filter dangling=true
       ```
     
     2. **Unused**
        These images are any that are not referenced by any container. 
     
     To get rid of both dangling and unused images, you can do the following:
     
     ```
     # IMPORTANT! This assumes all images you want to keep are connected to containers
     # that are currently running. We start by deleting all non-running containers.
     for stoppedContainer in $(docker ps --filter status=exited -q) ; do
       docker rm -f $stoppedContainer;
     done
     # The -a means both dangling AND "unused" images.
     sudo docker image prune -a -f
     ```
     
     
     
   - **Volume storage**
     None of the containers we run for kuali applications use [volumes](https://docs.docker.com/storage/volumes/) Instead they use [bind mounts](https://docs.docker.com/storage/bind-mounts/).
     That is, the containers mount directories that exist anywhere on the host file system. However, if for any reason containers have been run that use volumes, the data stored in those volumes is controlled by docker and stored here. The unused portion of these volumes can be trimmed.
     
     1.  **`/var/lib/docker/volumes/*/*`**
       Depending on the version of docker, the volume content will be stored here.
     
       ```
       docker info | grep -Pi '^((Server Version)|(Storage))'
       Server Version: 17.09.1-ce
       Storage Driver: devicemapper
       ```
     
     2. **`/var/lib/docker/overlay2/*/*`**
       Depending on the version of docker, the volume content may also be stored here.
     
       ```
       docker info | grep -Pi '^((Server Version)|(Storage))'
       Server Version: 17.06.2-ce
       Storage Driver: overlay2
       ```
     
     to trim off unused volume content in either of the two locations above, perform the image trimming detailed above and do the following:
     
     ```
     sudo docker volume prune -f
     ```
   
   If you want to see how much space docker is using, you can perform the following command before and after your trimming actions:
   
   ```
   docker system df
   TYPE                TOTAL               ACTIVE              SIZE                RECLAIMABLE
   Images              28                  5                   38.89GB             33.24GB (85%)
   Containers          5                   5                   393MB               0B (0%)
   Local Volumes       3                   0                   1.972GB             1.972GB (100%)
   Build Cache                                                 0B                  0B
   ```
   
   
   
2. **Tomcat and Apache logs**
   These accumulate in the following locations:

   - **`/var/log/tomcat`**
      The kuali monolith application runs in a container whose tomcat log folder bind mounts to this external folder. The logging method uses a rolling file appender and so old log files will gradually build up over time. In order to trim these logs choose an archived age in days and delete any log file in this directory that is older. By "archived age" is meant any log file that has not been written to (modified) for x days. Use the following command:

      ```
      days=30
      sudo find /var/log/tomcat -type f -mtime +${days} -exec rm -f {} \;
      ```

   - **`/var/log/httpd`**
      The apache-shibboleth application runs in a container whose httpd log folder bind mounts to this external folder. The logging method DOES NOT use a any kind of rolling file appender method and so each type of httpd log grows and is never "archived". 

      ```
      ls -lh /var/log/httpd
      -rw-r--r-- 1 root root 855M Apr  2 11:47 access_log
      -rw-r--r-- 1 root root  43K Apr  2 00:24 error_log
      -rw-r--r-- 1 root root 170M Apr  2 11:47 ssl_access_log
      -rw-r--r-- 1 root root 599K Mar  3 10:43 ssl_error_log
      -rw-r--r-- 1 root root 224M Apr  2 11:47 ssl_request_log
      ```

      One approach to trimming these logs is to decide how big the parent httpd folder must get in order to be a candidate for log pruning. If the size is decided to be 1 Gigabyte and the overall directory size exceeds this threshold you can handle the situation as follows:

      1. Verify the used space exceeds the 1 GB size:

         ```
         if [ -n "$(du -d1 /var/log/httpd | grep -Po '\d{7,}')" ] ; then
           echo 'Exceeds size one gigabyte!'
         else
           echo 'Does not exceed one gigabyte'
         fi
         ```

      2. Stop the apache docker container temporarily:

         ```
         docker stop apache-shibboleth
         ```

      3. (optional) Zip up the contents of the httpd directory and ship off anywhere you want.

      4. delete all of the log files:

         ```
         cd /var/log/httpd
         rm -f *_log
         ```

      5. Start the apache docker container back up:

         ```
         docker start apache-shibboleth
         ```

         

To automate all the actions above, a script is included in this repository: [DiskCleanup.sh](DiskCleanup.sh)
You can place this script file on any EC2 and run it or set it on a cron schedule as follows:

```
# You have shelled into an EC2 instance.

# 1) Sudo to root and go to the home directory (or some other directory), AND STAY THERE.
sudo su root
cd ~

# 2) Acquire DiskCleanup.md from this git repository
# You can cut and paste the old-fashioned way, or you could use the personal access token
# that belongs to the bu-ist-user github user. You can find this token under passwords in
# 1Password entitled "Personal Access Token for bu-ist-user"

curl \
  -H "Authorization: token ${token}" \
  -L https://api.github.com/repos/bu-ist/kuali-deployment-overview/contents/DiskCleanup.sh \
  | jq '.content' \
  | sed 's/\\n//g' \
  | sed 's/"//g' \
  | base64 --decode \
  > DiskCleanup.sh

# 3) Invoke a cleanup immediately:
# If you want to invoke all methods of cleanup (docker images, docker volumes, tomcat logs, apache logs)

sh DiskCleanup.sh --all
# or...
sh DiskCleanup.sh --images --volumes --tomcat --apache

# Or just some methods:
sh DiskCleanup.sh --images --tomcat

# To specify a cron schedule instead use --crontab. 
# This example invokes cleanup for images and tomcat on the 1st day of the month at 2AM
sh DiskCleanup.sh --images --tomcat --crontab '0 2 1 * *'
```

​     

**Notifications:**

If for any reason the above disk pruning measures fail to account for some runaway process that is filling up disk space, there are a number of ways to automate the monitoring of disk size and email notification for breaches in utilization thresholds.

