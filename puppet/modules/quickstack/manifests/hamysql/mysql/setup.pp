class quickstack::hamysql::mysql::setup (
  $keystone_db_password,
  $glance_db_password,
  $nova_db_password,
  $cinder_db_password,
  # Keystone
  $keystone_db_user       = 'keystone',
  $keystone_db_dbname     = 'keystone',
  # Glance
  $glance_db_user         = 'glance',
  $glance_db_dbname       = 'glance',
  # Nova
  $nova_db_user           = 'nova',
  $nova_db_dbname         = 'nova',
  # Cinder
  $cinder                 = true,
  $cinder_db_user         = 'cinder',
  $cinder_db_dbname       = 'cinder',
  # neutron
  $neutron                = true,
  $neutron_db_user        = 'neutron',
  $neutron_db_dbname      = 'neutron',
) {

  if str2bool("$hamysql_active_node") {
    class { 'quickstack::hamysql::mysql::account_security': }

    database { $keystone_db_dbname:
      ensure   => 'present',
      provider => 'mysql',
      require  => Class['quickstack::hamysql::mysql::rootpw'],
    }
    database_user { "$keystone_db_user@%":
      ensure => 'present',
      password_hash => mysql_password($keystone_db_password),
      provider      => 'mysql',
      require => Database[$keystone_db_dbname],
    }
    database_grant { "$keystone_db_user@%/$keystone_db_dbname":
      privileges => 'all',
      provider   => 'mysql',
      require    => Database_user["$keystone_db_user@%"]
    }

    database { $glance_db_dbname:
      ensure => 'present',
      provider => 'mysql',
    }
    database_user { "$glance_db_user@%":
      ensure => 'present',
      password_hash => mysql_password($glance_db_password),
      provider      => 'mysql',
      require => Database[$glance_db_dbname],
    }
    database_grant { "$glance_db_user@%/$glance_db_dbname":
      privileges => 'all',
      provider   => 'mysql',
      require    => Database_user["$glance_db_user@%"]
    }

    database { $nova_db_dbname:
      ensure => 'present',
      provider => 'mysql',
    }
    database_user { "$nova_db_user@%":
      ensure => 'present',
      password_hash => mysql_password($nova_db_password),
      provider      => 'mysql',
      require => Database[$nova_db_dbname],
    }
    database_grant { "$nova_db_user@%/$nova_db_dbname":
      privileges => 'all',
      provider   => 'mysql',
      require    => Database_user["$nova_db_user@%"]
    }

    database { $cinder_db_dbname:
      ensure => 'present',
      provider => 'mysql',
    }
    database_user { "$cinder_db_user@%":
      ensure => 'present',
      password_hash => mysql_password($cinder_db_password),
      provider      => 'mysql',
      require => Database[$cinder_db_dbname],
    }
    database_grant { "$cinder_db_user@%/$cinder_db_dbname":
      privileges => 'all',
      provider   => 'mysql',
      require    => Database_user["$cinder_db_user@%"]
    }
  }
}
