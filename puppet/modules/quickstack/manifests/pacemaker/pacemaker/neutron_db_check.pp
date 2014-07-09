class quickstack::pacemaker::neutron_db_check {

  if has_interface_with("ipaddress", map_params("cluster_control_ip")){
    exec { "neutron-db-check-update":
      command => "/usr/sbin/pcs resource create  neutron-db-check lsb:neutron-db-check meta failure-timeout=5 --group neutron-agents-pre",
    }
  }
}
