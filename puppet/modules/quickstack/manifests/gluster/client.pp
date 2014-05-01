# Quickstack gluster client
# This is a wrapper mostly for offering compatibility between soon to be
# deprecated puppet-openstack-storage version of gluster
# replaced with purpleidea/puppet-gluster module
class quickstack::gluster::client {
  class { 'gluster::mount::base': }
}
