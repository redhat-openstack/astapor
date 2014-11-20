# Hiera built-in data

## Setup
* Install Puppet and Git RPMs

`yum install -y puppet git`

* Install openstack-puppet-modules RPM

`yum -y install openstack-puppet-modules`

* Install Quickstack module from Openstack-Foreman-Installer RPM (RHEL-6-Server-OS-Foreman repo)

`yum -y install openstack-foreman-installer`
Alternatively use github source

* Create following link for Hiera to work with Puppet (BZ#1108039)

`ln -sf /etc/hiera.yaml /etc/puppet/hiera.yaml`

* classes should be available at hiera top level

`cp /usr/share/openstack-foreman-installer/puppet/modules/quickstack/data/classes.yaml /var/lib/hiera/defaults.yaml`

## Masterless Deployment - Neither Puppet master nor Foreman server needed

* Change values in YAML files accordingly

* Run Puppet on each node

```
puppet apply -e "hiera_include(<NODE_TYPE>)"  --modulepath=/usr/share/openstack-puppet/modules:/usr/share/openstack-foreman-installer/puppet/modules
```

where `<NODE_TYPE> ::= HA_AIO_classes | compute_classes`

## Notes
* Tested on RHO5/RHEL7
* Setenforce 0 - Nova scheduler: missing SELinux AVC (BZ#1149975)
* Compute class to be added soon
* The Openstack Puppet Modules includes module-data which allows YAML data to be built-in
