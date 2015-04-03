# Hiera built-in data for Quickstack

## Setup  
* Install Puppet and Git RPMs  
`yum install -y puppet git`

* Install openstack-puppet-modules RPM  
`yum -y install openstack-puppet-modules`

* Install Quickstack module from Openstack-Foreman-Installer RPM (RHEL-6-Server-OS-Foreman repo).
`yum -y install openstack-foreman-installer`

* Create following link for Hiera to work with Puppet (BZ#1108039)  
`ln -sf /etc/hiera.yaml /etc/puppet/hiera.yaml`

## Set the scene  
At installation time, the scenario is defined to 'HA' by default in /usr/share/openstack-foreman-installer/puppet/modules/quickstack/data/defaults.yaml

* To quickly override the scenario, define a new value using /var/lib/hiera/defaults.yaml:  
```
---
scenario: '<SCENARIO>'
```
Choosing <SCENARIO> from the following list:  
```
 HA
 HA-AIO
 HA-AIO-Neutron
 HA-AIO-Neutron-compute
 HA-Neutron
 Neutron-agents
 Neutron-ML2-OVS
 Nova-compute
 Nova-compute-Neutron-ML2-OVS
 NHA
 NHA-Neutron-agents
 NHA-Neutron-compute
 PCS-Neutron
 custom
```

* To check all available scenarios   
Lookup in modules/quickstack/data/classes.yaml file
or alternatively run:  
`puppet apply -e "include quickstack::scene" --modulepath=/usr/share/openstack-puppet/modules:/usr/share/openstack-foreman-installer/puppet/modules`

## Run  
* Masterless deployments where neither Puppet master nor Foreman server are needed  
Run Puppet on each node  
`puppet apply -e "include quickstack"  --modulepath=/usr/share/openstack-puppet/modules:/usr/share/openstack-foreman-installer/puppet/modules`

* Using the Foreman   
YAML parameters are propagated only when the Foreman setting for ENC parameters is turned off.

## Notes  
* Tested on RHEL7/OSP6
* Setenforce 0 - Nova scheduler: missing SELinux AVC (BZ#1149975)
* Scenarios scaffold in progress
* The Openstack Puppet Modules includes module-data which allows YAML data to be built-in
