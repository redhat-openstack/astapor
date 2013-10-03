# Glance Storage
class quickstack::glance_storage (
  $glance_backend_gluster      = $quickstack::params::glance_backend_gluster,
  $glance_backend_iscsi        = $quickstack::params::glance_backend_iscsi,
  $glance_gluster_volume       = $quickstack::params::glance_gluster_volume,
  $glance_gluster_peers        = $quickstack::params::glance_gluster_peers,
) inherits quickstack::params {
  class { 'glance::volume': }

  if $glance_backend_gluster == true {
    class { 'gluster::client': }

    mount { "/var/lib/glance":
    #  device  => ['glusterfs 192.168.0.4:/glance', 'glusterfs 192.168.0.5:/glance', 'glusterfs 192.168.0.6:/glance']
      device  => suffix($glance_gluster_peers, ":${glance_gluster_volume}"),
      fstype  => "glusterfs",
      ensure  => "mounted",
      options => "defaults,_netdev",
      atboot  => "true",
    }
  
# Following should be taken care by glance module
# mkdir -p /var/lib/glance/image-cache/
# mkdir -p /var/lib/glance/images
# chown -R glance:glance /var/lib/glance/images
# chown -R glance:glance /var/lib/glance/image-cache
# service openstack-glance-api restart
  }

  if $glance_backend_iscsi == true {
  }
}