# quickstack storage class
class quickstack::storage_backend (
  $storage = $quickstack::params::storage,
) inherits quickstack::params {
  case $cinder_storage_backend {
    'gluster': {  
      class { 'gluster::server': }

      class { 'quickstack::storage_backend::gluster::volume_cinder': }

      firewall { '001 RPC and gluster daemon incoming':
        proto    => 'tcp',
        dport    => [ '111', '24007', '24008' ],
        action   => 'accept',
      } 

      # 1 port per brick - We start with three
      firewall { '003 gluster bricks incoming':
        proto    => 'tcp',
        dport    => [ '24009', '24010', '24011'],
        action   => 'accept',
      } 
    }
    'iscsi': {
    }
  }
  
  case $glance_storage_backend {
    'gluster': {
      class { 'gluster::server': }

      class { 'quickstack::storage_backend::gluster::volume_glance': } 

      firewall { '001 RPC and gluster daemon incoming':
        proto    => 'tcp',
        dport    => [ '111', '24007', '24008' ],
        action   => 'accept',
      } 

      # 1 port per brick - We start with three
      firewall { '003 gluster bricks incoming':
        proto    => 'tcp',
        dport    => [ '24009', '24010', '24011'],
        action   => 'accept',
      } 
    }
    'iscsi': {
    }
  }
}
