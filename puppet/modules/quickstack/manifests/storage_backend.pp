# quickstack storage class
class quickstack::storage_backend (
  $storage = $quickstack::params::storage,
) inherits quickstack::params {
  case $storage_backend {
    'gluster': {
      class { 'quickstack::storage::gluster': }
    }
  }
}
