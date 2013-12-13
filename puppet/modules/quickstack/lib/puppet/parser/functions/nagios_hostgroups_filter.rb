module Puppet::Parser::Functions

# Services declared here must be defined in
# quickstack::monitor::nagios::server::openstack
  supported = [
    'neutron-server',
    'openstack-ceilometer-api',
    'openstack-cinder-api',
    'openstack-glance-api',
    'openstack-heat-api',
    'openstack-keystone',
    'openstack-nova-api',
    'openstack-nova-compute',
    'openstack-swift-api']

  newfunction(:nagios_hostgroups_filter, :type => :rvalue,
  :doc => "Returns provide list filtered out from unsupported services") do |args|
    # 'openstack-node' is default hostgroup for every node
    list = ['openstack-node']
    args[0].split(',').each { |service|
      list << service if supported.include?(service)
    }
    list.join(',')
  end
end
