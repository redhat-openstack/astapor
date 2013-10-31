class quickstack::hamysql::mysql::rootpw(
  $root_password     = 'UNSET',
  $old_root_password = '',
) {
  if $root_password != 'UNSET' {
    case $old_root_password {
      '':      { $old_pw='' }
      default: { $old_pw="-p'${old_root_password}'" }
    }
    exec { 'set_mysql_rootpw':
      command   => "mysqladmin -u root ${old_pw} password '${root_password}'",
      logoutput => true,
      unless    => "mysqladmin -u root -p'${root_password}' status > /dev/null",
      path      => '/usr/local/sbin:/usr/bin:/usr/local/bin:/bin',
      require   => File['/etc/mysql/conf.d'],
      onlyif    => "/tmp/are-we-running-mysql.bash",
    }
    file { "${root_home}/.my.cnf":
      content => template('mysql/my.cnf.pass.erb'),
      require => Exec['set_mysql_rootpw'],
      mode => '0600',
    }

  }
}