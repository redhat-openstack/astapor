# quickstack storage class
class quickstack::storage_backend (
  $storage = $quickstack::params::storage,
) inherits quickstack::params {
  case $cinder_storage_backend {
    'gluster': {  
      class { 'gluster::server': }

      class { 'quickstack::storage_backend::gluster::volume::cinder': }
    }
    'iscsi': {
    }
  }
  
  case $glance_storage_backend {
    'gluster': {
      class { 'gluster::server': }

      class { 'quickstack::storage_backend::gluster::volume::glance': }
    }
    'iscsi': {
    }
  }
}
