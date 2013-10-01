# quickstack storage class
class quickstack::storage_backend::gluster {
  class { 'gluster::server': }

  class { 'quickstack::storage_backend::gluster::volume_cinder': }
 
  class { 'quickstack::storage_backend::gluster::volume_glance': } 

#  class { 'quickstack::storage_backend::gluster::volume_swift': } 

  firewall { '001 RPC and gluster daemon incoming':
    proto  => 'tcp',
    dport  => [ '111', '24007', '24008' ],
    action => 'accept',
  } 

  # 1 port per brick - We start with three
  firewall { '002 gluster bricks incoming':
    proto  => 'tcp',
    #dport  => port_range('24009', '6'),
    dport    => [ '24009', '24010', '24011' ],
    action => 'accept',
  } 
}
