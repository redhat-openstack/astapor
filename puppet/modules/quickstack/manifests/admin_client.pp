class quickstack::admin_client(
  $admin_password,
  $controller_admin_host,
) {

  define openstack_client_pkgs() {
    if ! defined(Package[$name]) {
      package { $name: ensure => 'installed' }
    }
  }

  
  $clientdeps = ["python-iso8601"]
  $clientlibs = [ "python-novaclient", 
                  "python-keystoneclient", 
                  "python-glanceclient", 
                  "python-cinderclient", 
                  "python-neutronclient", 
                  "python-swiftclient", 
                  "python-heatclient" ]

  openstack_client_pkgs { $clientdeps: }
  openstack_client_pkgs { $clientlibs: }

  $rcadmin_content = "export OS_USERNAME=admin 
export OS_TENANT_NAME=admin   
export OS_PASSWORD=$admin_password
export OS_AUTH_URL=http://$controller_admin_host:35357/v2.0/
export PS1='[\\u@\\h \\W(openstack_admin)]\\$ '
"

  file {"/root/keystonerc_admin":
     ensure  => "present",
     mode => '0600',
     content => $rcadmin_content,
  }
}
