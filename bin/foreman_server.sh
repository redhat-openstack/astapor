#!/bin/bash

echo "#################### RED HAT OPENSTACK #####################"
echo "Thank you for using the Red Hat OpenStack Foreman Installer!"
echo "Please note that this tool is a Technology Preview"
echo "For more information about Red hat Technology Previews, see"
echo "https://access.redhat.com/support/offerings/techpreview/"
echo "############################################################"

read -p "Press [Enter] to continue"

# PUPPETMASTER is the fqdn that needs to be resolvable by clients.
# Change if needed
if [ "x$PUPPETMASTER" = "x" ]; then
  # Set PuppetServer
  #export PUPPETMASTER=puppet.example.com
  export PUPPETMASTER=$(hostname --fqdn)
fi

if `echo $PUPPETMASTER | grep -v -q '\.'`; then
  echo "PUPPETMASTER has a value of $PUPPETMASTER but it must be a fqdn"
  exit 1
fi

# FOREMAN_PROVISIONING determines whether configure foreman for bare
# metal provisioning including installing dns and dhcp servers.
if [ "x$FOREMAN_PROVISIONING" = "x" ]; then
  FOREMAN_PROVISIONING=true
fi

# openstack networking configs.  These must be set to something sensible.
#PRIVATE_CONTROLLER_IP=10.0.0.10
#PRIVATE_INTERFACE=eth1
#PRIVATE_NETMASK=10.0.0.0/23
#PUBLIC_CONTROLLER_IP=10.9.9.10
#PUBLIC_INTERFACE=eth2
#PUBLIC_NETMASK=10.9.9.0/24
#ADMIN_CONTROLLER_IP=10.8.8.10 (This is for admin endpoints)
#FOREMAN_GATEWAY=10.0.0.1 (or false for no gateway)
if [ "x$PRIVATE_CONTROLLER_IP" = "x" ]; then
  echo "You must define PRIVATE_CONTROLLER_IP before running this script"
  exit 1
fi
if [ "x$PRIVATE_INTERFACE" = "x" ]; then
  echo "You must define PRIVATE_INTERFACE before running this script"
  exit 1
fi
if [ "x$PRIVATE_NETMASK" = "x" ]; then
  echo "You must define PRIVATE_NETMASK before running this script"
  exit 1
fi
if [ "x$PUBLIC_CONTROLLER_IP" = "x" ]; then
  echo "You must define PUBLIC_CONTROLLER_IP before running this script"
  exit 1
fi
if [ "x$PUBLIC_INTERFACE" = "x" ]; then
  echo "You must define PUBLIC_INTERFACE before running this script"
  exit 1
fi
if [ "x$PUBLIC_NETMASK" = "x" ]; then
  echo "You must define PUBLIC_NETMASK before running this script"
  exit 1
fi
if [ "x$ADMIN_CONTROLLER_IP" = "x" ]; then
  echo "You must define ADMIN_CONTROLLER_IP before running this script"
  echo "Alternatively you can use either private or public IP"
  exit 1
fi
if [ "x$FOREMAN_GATEWAY" = "x" ]; then
  echo "You must define FOREMAN_GATEWAY before running this script"
  echo "  Use either the gateway IP for the internal Foreman network, or"
  echo "  use 'false' to have no gateway offered for non-routable networks"
  exit 1
fi

if [ "x$SCL_RUBY_HOME" = "x" ]; then
  SCL_RUBY_HOME=/opt/rh/ruby193/root
fi

if [ "x$PACKSTACK_HOME" = "x" ]; then
  PACKSTACK_HOME=/usr/share/packstack
fi

if [ "x$QUICKSTACK_HOME" = "x" ]; then
  QUICKSTACK_HOME=$(cd $(dirname ${BASH_SOURCE[0]})/.. && pwd)
fi

if [ "x$FOREMAN_INSTALLER_DIR" = "x" ]; then
  FOREMAN_INSTALLER_DIR=/usr/share/foreman-installer
fi

if [ "x$FOREMAN_DIR" = "x" ]; then
  FOREMAN_DIR=/usr/share/foreman
fi

if [ ! -d $FOREMAN_INSTALLER_DIR ]; then
  echo "$FOREMAN_INSTALLER_DIR does not exist.  exiting"
  exit 1
fi

if [ ! -f foreman_server.sh ]; then
  echo "You must be in the same dir as foreman_server.sh when executing it"
  exit 1
fi

if [ ! -f /etc/redhat-release ] || \
    cat /etc/redhat-release | grep -v -q -P 'release 6.[456789]'; then
  echo "This installer is only supported on RHEL 6.4 or greater."
  exit 1
fi

if [ "$FOREMAN_PROVISIONING" = "true" ]; then
  NUM_INT=$(facter -p|grep ipaddress_|grep -v _lo|wc -l)
  if [[ $NUM_INT -lt 2 ]] ; then
    echo "This installer needs 2 configured interfaces - only $NUM_INT detected"
    exit 1
  fi
  PRIMARY_INT=$(route|grep default|awk ' { print ( $(NF) ) }')
  PRIMARY_PREFIX=$(facter network_${PRIMARY_INT} | cut -d. -f1-3)
  SECONDARY_INT=$(facter -p|grep ipaddress_|grep -Ev "_lo|$PRIMARY_INT"|awk -F"[_ ]" '{print $2;exit 0}')
  SECONDARY_PREFIX=$(facter network_${SECONDARY_INT} | cut -d. -f1-3)
  SECONDARY_REVERSE=$(echo "$SECONDARY_PREFIX" | ( IFS='.' read a b c ; echo "$c.$b.$a.in-addr.arpa" ))
  FORWARDER=$(augtool get /files/etc/resolv.conf/nameserver[1] | awk '{printf $NF}')
fi

# start with a subscribed RHEL6 box.  hint:
#    subscription-manager register
#    subscription-manager subscribe --auto

# enable ip forwarding
sudo sysctl -w net.ipv4.ip_forward=1
sudo sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/sysctl.conf

# disable selinux in /etc/selinux/config
# TODO: selinux policy
setenforce 0

# Puppet configuration
augtool -s <<EOA
set /files/etc/puppet/puppet.conf/agent/server $PUPPETMASTER
set /files/etc/puppet/puppet.conf/main/pluginsync true
EOA

# fix db migrate script for scl
cp ../config/dbmigrate $FOREMAN_DIR/extras/
# fix broken passenger config file for scl
cp ../config/broker-ruby $FOREMAN_DIR
chmod 775 $FOREMAN_DIR/broker-ruby

pushd $FOREMAN_INSTALLER_DIR
cat > installer.pp << EOM
class { 'puppet':
  runmode => 'cron',
  server  => true,
  server_common_modules_path => [
    '$QUICKSTACK_HOME/puppet/modules',
    '$PACKSTACK_HOME/modules',
  ],
}
include passenger
class { 'foreman':
  db_type => 'mysql',
  custom_repo => true
}
#
# Check foreman_proxy/manifests/{init,params}.pp for other options
class { 'foreman_proxy':
  custom_repo          => true,
  port                 => '9090',
  registered_proxy_url => "https://\${::fqdn}:9090",
EOM

if [ "$FOREMAN_PROVISIONING" = "true" ]; then
cat >> installer.pp << EOM
  tftp_servername  => '$(facter ipaddress_${SECONDARY_INT})',
  dhcp             => true,
  dhcp_gateway     => '${FOREMAN_GATEWAY}',
  dhcp_range       => '${SECONDARY_PREFIX}.50 ${SECONDARY_PREFIX}.200',
  dhcp_interface   => '${SECONDARY_INT}',

  dns              => true,
  dns_reverse      => '${SECONDARY_REVERSE}',
  dns_forwarders   => ['${FORWARDER}'],
  dns_interface    => '${SECONDARY_INT}',
}
EOM

else
cat >> installer.pp << EOM
  dhcp             => false,
  dns              => false,
  tftp             => false,
}
EOM

fi

puppet apply --verbose installer.pp --modulepath=modules
popd

# turn on certificate autosigning
# GSutcliffe: Should be uneccessary once Foreman Provisioning is shown to be working
echo '*' >> /etc/puppet/autosign.conf

# Import puppet class definitions into Foreman
sudo -u foreman scl enable ruby193 "cd $FOREMAN_DIR; RAILS_ENV=production rake puppet:import:puppet_classes[batch]"

# Set params, and run the db:seed file to set class parameter defaults
cp ./seeds.rb $FOREMAN_DIR/db/.
sed -i "s#SECONDARY_INT#$SECONDARY_INT#" $FOREMAN_DIR/db/seeds.rb
sed -i "s#PRIV_INTERFACE#$PRIVATE_INTERFACE#" $FOREMAN_DIR/db/seeds.rb
sed -i "s#PUB_INTERFACE#$PUBLIC_INTERFACE#" $FOREMAN_DIR/db/seeds.rb
sed -i "s#PRIV_IP#$PRIVATE_CONTROLLER_IP#" $FOREMAN_DIR/db/seeds.rb
sed -i "s#PUB_IP#$PUBLIC_CONTROLLER_IP#" $FOREMAN_DIR/db/seeds.rb
sed -i "s#ADMIN_IP#$ADMIN_CONTROLLER_IP#" $FOREMAN_DIR/db/seeds.rb
sed -i "s#PRIV_RANGE#$PRIVATE_NETMASK#" $FOREMAN_DIR/db/seeds.rb
sed -i "s#PUB_RANGE#$PUBLIC_NETMASK#" $FOREMAN_DIR/db/seeds.rb
sudo -u foreman scl enable ruby193 "cd $FOREMAN_DIR; rake db:seed RAILS_ENV=production FOREMAN_PROVISIONING=$FOREMAN_PROVISIONING"

if [ "$FOREMAN_PROVISIONING" = "true" ]; then
  # Write the TFTP default file
  curl --user 'admin:changeme' -k 'https://127.0.0.1/api/config_templates/build_pxe_default'
fi

# write client-register-to-foreman script
# TODO don't hit yum unless packages are not installed
cat >/tmp/foreman_client.sh <<EOF

# start with a subscribed RHEL6 box needs optional channels and epel
yum install -y augeas puppet nc

# Puppet configuration
augtool -s <<EOA
set /files/etc/puppet/puppet.conf/agent/server $PUPPETMASTER
set /files/etc/puppet/puppet.conf/main/pluginsync true
EOA

# check in to foreman
puppet agent --test
sleep 1
puppet agent --test

service puppet start
chkconfig puppet on
EOF

echo "Foreman is installed and almost ready for setting up your OpenStack"
echo "You'll find Foreman at https://$(hostname)"
echo "The user name is 'admin' and default password is 'changeme'."
echo "Please change the password at https://$(hostname)/users/1-admin/edit"
echo ""
echo "Then you need to alter a few parameters in Foreman."
echo "Visit: https://$(hostname)/hostgroups"
echo "From this list, click on each class that you plan to use"
echo "Go to the Smart Class Parameters tab and work though each of the parameters"
echo "in the left-hand column"
echo ""
echo "Then copy /tmp/foreman_client.sh to your openstack client nodes"
echo "Run that script and visit the HOSTS tab in foreman. Pick some"
echo "host groups for your nodes based on the configuration you prefer"
echo "For further directions, see:"
echo "http://openstack.redhat.com/Deploying_RDO_Using_Foreman"
echo ""
echo "Once puppet runs on the machines, OpenStack is ready!"
