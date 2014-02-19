#!/bin/sh
[[ $(rpm -qa | grep ^git-) ]] || (yum install -y -q git && sleep 5)
#[[ "$(gem query -i -n r10k)" == "true" ]] || gem install --no-rdoc --no-ri r10k
#cd /vagrant && r10k -v info puppetfile install

name=${1}

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
hostname ${name}.localnet
augtool -s < /vagrant/bootstrap/hostnames.aug

#
# Upgrade or install some target packages ... needs to go away into puppet.
#
UP_RPMS="iproute"
RPMS="sheepdog python-cinderclient"
yum -y upgrade ${IP_RPMS}
yum -y install ${RPMS}

#
# Configure puppet and register
#
yum install -y augeas puppet nc

augtool -s <<EOA
set /files/etc/puppet/puppet.conf/agent/server    foreman.localnet 
set /files/etc/puppet/puppet.conf/agent/ca_server foreman.localnet 
set /files/etc/puppet/puppet.conf/main/pluginsync true
EOA

[ -d /var/lib/puppet/ssl ] && rm -rf /var/lib/puppet/ssl

puppet agent --test; sleep 1; puppet agent --test

#service puppet restart
#chkconfig puppet on




