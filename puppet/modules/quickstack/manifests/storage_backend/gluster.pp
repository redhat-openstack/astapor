class quickstack::storage_backend::gluster {

	class { 'gluster::server': }

	class { 'quickstack::storage::gluster::volume': }

}