class quickstack::hamysql::node (
  $mysql_root_password         = $quickstack::params::mysql_root_password,
  $keystone_db_password        = $quickstack::params::keystone_db_password,
  $glance_db_password          = $quickstack::params::glance_db_password,
  $nova_db_password            = $quickstack::params::nova_db_password,
  $cinder_db_password          = $quickstack::params::cinder_db_password,
  $heat_db_password            = $quickstack::params::heat_db_password,
  $neutron_db_password         = $quickstack::params::neutron_db_password,
  $neutron                     = $quickstack::params::neutron,

  # these two variables are distinct because you may want to bind on
  # '0.0.0.0' rather than just the floating ip
  $mysql_bind_address           = $quickstack::params::mysql_host,
  $mysql_virtual_ip             = $quickstack::params::mysql_host,
  $mysql_virtual_ip_managed     = "true",
  $mysql_virt_ip_nic            = $quickstack::params::mysql_virt_ip_nic,
  $mysql_virt_ip_cidr_mask      = $quickstack::params::mysql_virt_ip_cidr_mask,
  # e.g. "192.168.200.200:/mnt/mysql"
  $mysql_shared_storage_device  = $quickstack::params::mysql_shared_storage_device,
  # e.g. "nfs"
  $mysql_shared_storage_type    = $quickstack::params::mysql_shared_storage_type,
  #
  $mysql_shared_storage_options = $quickstack::params::mysql_shared_storage_options,
  $mysql_resource_group_name    = $quickstack::params::mysql_resource_group_name,
  $mysql_clu_member_addrs       = $quickstack::params::mysql_clu_member_addrs,
  $corosync_setup               = true,
  $cluster_control_ip           = '',
) inherits quickstack::params {

    include mysql::python

    $mysql_virtual_ip_managed_bool = str2bool_i("$mysql_virtual_ip_managed")
    $pcs_resource_setup = has_interface_with("ipaddress", $cluster_control_ip)

    if ($::osfamily == 'RedHat' and
      $::operatingsystem != 'Fedora' and
      $::operatingsystemrelease =~ /^6\..*$/) {
      package { 'mysql-server':
        ensure => installed,
      }
      Package['mysql-server'] -> Class['quickstack::hamysql::mysql::config']
    } else {
      package { 'mariadb-galera-server':
        ensure => installed,
      }
      Package['mariadb-galera-server'] -> Class['quickstack::hamysql::mysql::config']
    }

    class {'quickstack::hamysql::mysql::config':
      bind_address =>  $mysql_bind_address,
      socket => '/var/run/mysqld/mysql.sock',
    }
    -> Class['pacemaker::corosync']
    if ($mysql_virtual_ip_managed_bool and $pcs_resource_setup) {
      Class['pacemaker::corosync']
      -> ::Pacemaker::Resource::Ip['mysql-clu-vip']
    }
    if $corosync_setup {
      class {'pacemaker::corosync':
        cluster_name => "hamysql",
        cluster_members => $mysql_clu_member_addrs,
      }
      if ($mysql_virtual_ip_managed_bool and $pcs_resource_setup) {
        # TODO: use quickstack::pacemaker::common instead
        class {"pacemaker::stonith":
          disable => true,
        } ->
        Class['pacemaker::corosync']
        -> ::Pacemaker::Resource::Ip['mysql-clu-vip']
      }
    }
    if ($mysql_virtual_ip_managed_bool and $pcs_resource_setup) {
      ::pacemaker::resource::ip { 'mysql-clu-vip' :
        ip_address => $mysql_virtual_ip,
        group => $mysql_resource_group_name,
        cidr_netmask => $mysql_virt_ip_cidr_mask,
        nic => $mysql_virt_ip_nic,
      }
      ::pacemaker::constraint::base { 'ip-mysql-constr' :
        constraint_type => "order",
        first_resource  => "ip-${mysql_virtual_ip}",
        second_resource => "mysql-ostk-mysql",
        first_action    => "start",
        second_action   => "start",
      }
      ::Pacemaker::Resource::Ip['mysql-clu-vip'] ->
      ::Pacemaker::Resource::Filesystem['mysql-clu-fs']

      ::Pacemaker::Constraint::Base['fs-mysql-constr'] ->
      ::Pacemaker::Constraint::Base['ip-mysql-constr']
    }
    if ($pcs_resource_setup) {
      ::pacemaker::resource::filesystem { 'mysql-clu-fs' :
        device => "$mysql_shared_storage_device",
        directory => "/var/lib/mysql",
        fstype => $mysql_shared_storage_type,
        fsoptions => $mysql_shared_storage_options,
        group => $mysql_resource_group_name,
      }
      -> Exec['wait-for-fs-to-be-active']
    }
    exec {"wait-for-fs-to-be-active":
      timeout => 3600,
      tries => 360,
      try_sleep => 10,
      command => "/usr/sbin/pcs status  | grep -q 'fs-varlibmysql.*Started' > /dev/null 2>&1",
    }
    ->
    exec { "sleep-so-really-sure-fs-is-mounted":
      command => "/bin/sleep 5",
    }
    ->
    # this needs to be an exec rather than puppet's file type because
    # the link must *only* be attempted to be created on the node that has
    # shared storage mounted.  /var/lib/mysql must not contain
    # any files on the other nodes so it can be used as a mount point.
    exec { "create-socket-symlink-if-we-own-the-mount":
      command => "/bin/ln -sf /var/run/mysqld/mysql.sock /var/lib/mysql/mysql.sock",
      onlyif => "/bin/mount | grep -q '/var/lib/mysql'",
    }
    -> Exec['wait-for-mysql-to-start']
    if ($pcs_resource_setup) {
      Exec['create-socket-symlink-if-we-own-the-mount']
      ->
      ::pacemaker::resource::mysql { 'mysql-clu-mysql' :
        name => "ostk-mysql",
        group => $mysql_resource_group_name,
        additional_params => "socket=/var/run/mysqld/mysql.sock",
      }
      ->
      ::pacemaker::constraint::base { 'fs-mysql-constr' :
        constraint_type => "order",
        first_resource  => "fs-varlibmysql",
        second_resource => "mysql-ostk-mysql",
        first_action    => "start",
        second_action   => "start",
      }
      -> Exec['wait-for-mysql-to-start']
    }
    exec {"wait-for-mysql-to-start":
      timeout => 3600,
      tries => 360,
      try_sleep => 10,
      command => "/usr/sbin/pcs status  | grep -q 'mysql-ostk-mysql.*Started' > /dev/null 2>&1",
    }

    class {'quickstack::hamysql::mysql::rootpw':
      require => File['are-we-running-mysql-script'],
      root_password => $mysql_root_password,
    }

    file {"are-we-running-mysql-script":
      name => "/tmp/are-we-running-mysql.bash",
      ensure => present,
      owner => root,
      group => root,
      mode  => 777,
      content => "#!/bin/bash\n a=`/usr/sbin/pcs status | grep -P 'mysql-ostk-mysql\\s.*Started' | perl -p -e 's/^.*Started (\\S*).*$/\$1/'`; b=`/usr/sbin/crm_node -n`; echo \$a; echo \$b; \ntest \$a = \$b;\n",
      require => Exec['wait-for-mysql-to-start'],
    }

    class {'quickstack::hamysql::mysql::setup':
      keystone_db_password => $keystone_db_password,
      glance_db_password   => $glance_db_password,
      nova_db_password     => $nova_db_password,
      cinder_db_password   => $cinder_db_password,
      heat_db_password     => $heat_db_password,
      neutron_db_password  => $neutron_db_password,
      neutron              => str2bool_i("$neutron"),
      require              => Class['quickstack::hamysql::mysql::rootpw'],
    }
    firewall { '002 mysql incoming':
      proto => 'tcp',
      dport => ['3306'],
      action => 'accept',
    }
}
