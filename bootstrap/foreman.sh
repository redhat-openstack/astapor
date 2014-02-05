#!/bin/sh
[[ $(rpm -qa | grep ^git-) ]] || (yum install -y -q git && sleep 5)
#[[ "$(gem query -i -n r10k)" == "true" ]] || gem install --no-rdoc --no-ri r10k
#cd /vagrant && r10k -v info puppetfile install

#
# Setup needed repos, and install useful config mgmt tools
#

RDO_RPM=http://repos.fedorapeople.org/repos/openstack/openstack-havana/rdo-release-havana-7.noarch.rpm
EPEL_RPM=http://mirror.pnl.gov/epel/6/i386/epel-release-6-8.noarch.rpm

yum -y remove puppetlabs-release
yum -y install ${RDO_RPM}
yum -y install ${EPEL_RPM}

yum -y install crudini
[ -r /etc/yum/pluginconf.d/priorities.conf ] && crudini --set /etc/yum/pluginconf.d/priorities.conf main enabled 0

yum -y install augeas

#
# Setup hostnames properly & consistently 
#

# Setup hostnames
#
hostname foreman.localnet
augtool -s < /vagrant/bootstrap/hostnames.aug

#
# Update packages
#
#yum -y upgrade 

#
# Install required packages
#
RPMS="augeas mysql-server packstack-modules-puppet \
      foreman-installer foreman foreman-plugin-simplify "

yum -y install ${RPMS}

#
# Run the foreman installer
#
chmod -R a+rX /vagrant
cd /vagrant/bin
export FOREMAN_PROVISIONING=false # Will foreman be used for provisioning? true or false
export FOREMAN_GATEWAY=false      # The gateway set up for foreman provisioning
echo "" | bash -x ./foreman_server.sh

