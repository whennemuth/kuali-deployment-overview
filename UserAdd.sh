#!/bin/bash

cat <<EOF > /tmp/addUser.sh
username="$1"
pubkey="$2"

if [ ! -d /home/\$username ] ; then
  useradd -d /home/\$username -m -s /bin/bash \$username
  usermod -a -G root \$username
  usermod -a -G wheel \$username
  usermod -a -G docker \$username
fi

if [ ! -d /home/\$username/.ssh ] ; then
  mkdir -m 700 /home/\$username/.ssh
  cd /home/\$username/.ssh
  echo "\$pubkey" >> authorized_keys
  chmod 600 authorized_keys
  chown -R \$username:docker /home/\$username/.ssh
fi
EOF
