# cut and paste of mysql::server::account_security minus requires on
# Class['mysql::config']
class quickstack::hamysql::mysql::account_security {
  # Some installations have some default users which are not required.
  # We remove them here. You can subclass this class to overwrite this behavior.
  database_user { [ "root@${::fqdn}", 'root@127.0.0.1', 'root@::1',
                    "@${::fqdn}", '@localhost', '@%' ]:
    ensure  => 'absent',
  }
  if ($::fqdn != $::hostname) {
    database_user { ["root@${::hostname}", "@${::hostname}"]:
      ensure  => 'absent',
    }
  }
  database { 'test':
    ensure  => 'absent',
  }
}
