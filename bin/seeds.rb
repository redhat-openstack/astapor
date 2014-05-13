# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)

# Libs
require 'facter'
require 'securerandom'

# for the sub-network foreman owns
secondary_int = 'PROVISIONING_INTERFACE'

# Changes from upstream:
#  - EPEL removed
#  - SELinux enforcing
#  - puppet removed from %packages
# Template texts - the trailing newline is important!
provision_text='install
<%= @mediapath %>
lang en_US.UTF-8
selinux --enforcing
keyboard us
skipx
network --bootproto <%= @static ? "static" : "dhcp" %> --hostname <%= @host %>
rootpw --iscrypted <%= root_pass %>
firewall --<%= @host.operatingsystem.major.to_i >= 6 ? "service=" : "" %>ssh
authconfig --useshadow --passalgo=sha256 --kickstart
timezone UTC
services --disabled autofs,gpm,sendmail,cups,iptables,ip6tables,auditd,arptables_jf,xfs,pcmcia,isdn,rawdevices,hpoj,bluetooth,openibd,avahi-daemon,avahi-dnsconfd,hidd,hplip,pcscd,restorecond,mcstrans,rhnsd,yum-updatesd

bootloader --location=mbr --append="nofb quiet splash=quiet" <%= grub_pass %>
key --skip

<% if @dynamic -%>
%include /tmp/diskpart.cfg
<% else -%>
<%= @host.diskLayout %>
<% end -%>

text
reboot

%packages --ignoremissing
yum
dhclient
ntp
wget
redhat-lsb-core
@Core

<% if @dynamic -%>
%pre
<%= @host.diskLayout %>
<% end -%>

%post --nochroot
exec < /dev/tty3 > /dev/tty3
#changing to VT 3 so that we can see whats going on....
/usr/bin/chvt 3
(
cp -va /etc/resolv.conf /mnt/sysimage/etc/resolv.conf
/usr/bin/chvt 1
) 2>&1 | tee /mnt/sysimage/root/install.postnochroot.log

%post
logger "Starting anaconda <%= @host %> postinstall"
exec < /dev/tty3 > /dev/tty3
#changing to VT 3 so that we can see whats going on....
/usr/bin/chvt 3
(
#update local time
echo "updating system time"
/usr/sbin/ntpdate -sub <%= @host.params["ntp-server"] || "0.fedora.pool.ntp.org" %>
/usr/sbin/hwclock --systohc

<%= snippets "redhat_register" %>

# update all the base packages from the updates repository
yum -t -y -e 0 update

# and add the puppet package
yum -t -y -e 0 install puppet

echo "Configuring puppet"
cat > /etc/puppet/puppet.conf << EOF
<%= snippets "puppet.conf" %>
EOF

# Setup puppet to run on system reboot
/sbin/chkconfig --level 345 puppet on

puppet agent -o --tags no_such_tag --server <%= @host.puppetmaster %>  --no-daemonize

sync

# Inform the build system that we are done.
echo "Informing Foreman that we are built"
wget -q -O /dev/null --no-check-certificate <%= foreman_url %>
# Sleeping an hour for debug
) 2>&1 | tee /root/install.post.log
exit 0
'
pxe_text='default linux
label linux
IPAPPEND 2
kernel <%= @kernel %>
append initrd=<%= @initrd %> ks=<%= foreman_url("provision")%> ksdevice=bootif network kssendmac
'
ptable_text='zerombr
clearpart --all --initlabel
autopart
'

# Disable CA management as the proxy has issues using sudo with SCL
Setting[:manage_puppetca] = false

# Set correct hostname
Setting[:foreman_url] = Facter.value(:fqdn)

# Create an OS to assign things to. We'll come back later to finish it's config
os = Operatingsystem.where(:name => "RedHat", :major => "6", :minor => "4").first
os ||= Operatingsystem.create(:name => "RedHat", :major => "6", :minor => "4")
os.type = "Redhat"
os.description = "RHEL Server 6.4" if os.respond_to? :description=
os.save!

# Installation Media - comes as standard, just need to associate it
# For RHEL this is the Binary DVD image from rhn.redhat.com downloads, loopback
# mounted and made available over HTTP.
m=Medium.find_or_create_by_name("OpenStack RHEL mirror")
m.path="http://mirror.example.com/rhel/$major.$minor/os/$arch"
m.os_family="Redhat"
m.operatingsystems << os
m.save!

# OS parameters for RHN(S) registration, see redhat_register snippet
{
  # use Subscription Manager, not Satellite
  "subscription_manager" => "true",

  "subscription_manager_username" => "username",
  "subscription_manager_password" => "password",
  # for load balancer also enable "rhel-lb-for-rhel-6-server-rpms"
  "subscription_manager_repos" => "rhel-6-server-rpms,rhel-6-server-openstack-4.0-rpms",

  # if using SAM/Katello
  # "subscription_manager_host" => "katello.example.com",
  # "subscription_manager_org" => "organization",

  # if using Satellite
  # "site" for local Satellite, "hosted" for RHN
  # "satellite_type" => "site",
  # "satellite_host" => "satellite.example.com",

  # if using Satellite or SAM/Katello
  # Activation key must have OpenStack child channel
  # "activation_key" => "1-example",
}.each do |k,v|
  p=OsParameter.find_or_create_by_name(k)
  p.value = v
  p.reference_id = os.id
  p.save!
end

# Add Proxy
# Figure out how to call this before the class import
# SmartProxy.new(:name => "OpenStack Smart Proxy", :url => "https://#{Facter.value(:fqdn)}:8443"

# Architectures
a=Architecture.find_or_create_by_name "x86_64"
a.operatingsystems << os
a.save!

if ENV["FOREMAN_PROVISIONING"] == "true" then
  # Domains
  d=Domain.find_or_create_by_name Facter.value(:domain)
  d.fullname="OpenStack: #{Facter.value(:domain)}"
  d.dns = Feature.find_by_name("DNS").smart_proxies.first
  d.save!

  # Subnets - use Import Subnet code
  s=Subnet.find_or_create_by_name "OpenStack"
  s.network=Facter.value("network_#{secondary_int}")
  s.mask=Facter.value("netmask_#{secondary_int}")
  s.dhcp = Feature.find_by_name("DHCP").smart_proxies.first
  s.dns = Feature.find_by_name("DNS").smart_proxies.first
  s.tftp = Feature.find_by_name("TFTP").smart_proxies.first
  s.domains=[d]
  s.save!

  # Templates
  pt   = Ptable.find_or_initialize_by_name "OpenStack Disk Layout"
  data = {
    :layout           => ptable_text,
    :os_family        => "Redhat"
  }
  pt.update_attributes(data)
  pt.save!

  pxe = ConfigTemplate.find_or_initialize_by_name "OpenStack PXE Template"
  data = {
    :template         => pxe_text,
    :operatingsystems => ( pxe.operatingsystems << os ).uniq,
    :snippet          => false,
    :template_kind_id => TemplateKind.find_by_name("PXELinux").id
  }
  pxe.update_attributes(data)
  pxe.save!

  ks = ConfigTemplate.find_or_initialize_by_name "OpenStack Kickstart Template"
  data = {
    :template         => provision_text,
    :operatingsystems => ( ks.operatingsystems << os ).uniq,
    :snippet          => false,
    :template_kind_id => TemplateKind.find_by_name("provision").id
  }
  ks.update_attributes(data)
  ks.save!

  # Finish updating the OS
  os.ptables = [pt]
  ['provision','PXELinux'].each do |kind|
    kind_id = TemplateKind.find_by_name(kind).id
    id = kind == 'provision' ? ks.id : pxe.id
    if os.os_default_templates.where(:template_kind_id => kind_id).blank?
      os.os_default_templates.build(:template_kind_id => kind_id, :config_template_id => id)
    else
      odt = os.os_default_templates.where(:template_kind_id => kind_id).first
      odt.config_template_id = id
      odt.save!
    end
  end
  os.save!

  # Override all the puppet class params for quickstack
  primary_int=`route|grep default|awk ' { print ( $(NF) ) }'`.chomp
  primary_prefix=Facter.value("network_#{primary_int}").split('.')[0..2].join('.')
  sec_int_hash=Facter.to_hash.reject { |k| k !~ /^ipaddress_/ }.reject { |k| k =~ /lo|#{primary_int}/ }.first
  secondary_int=sec_int_hash[0].split('_').last
  secondary_prefix=sec_int_hash[1].split('.')[0..2].join('.')
end

params = {
  "verbose"                       => "true",
  "heat_cfn"                      => "true",
  "heat_cloudwatch"               => "false",
  "admin_password"                => SecureRandom.hex,
  "ceilometer_metering_secret"    => SecureRandom.hex,
  "ceilometer_user_password"      => SecureRandom.hex,
  "cinder_db_password"            => SecureRandom.hex,
  "cinder_user_password"          => SecureRandom.hex,
  "cinder_backend_gluster"        => "false",
  "cinder_backend_gluster_name"   => "glusterfs_backend",
  "cinder_backend_rbd"            => "false",
  "cinder_backend_rbd_name"       => 'rbd_backend',
  "cinder_backend_iscsi"          => "false",
  "cinder_backend_iscsi_name"     => "iscsi_backend",
  "cinder_backend_nfs"            => "false",
  "cinder_backend_nfs_name"       => "nfs_backend",
  "cinder_backend_eqlx"           => "false",
  "cinder_backend_eqlx_name"      => ["eqlx_backend"],
  "cinder_multiple_backends"      => "false",
  "cinder_gluster_device"         => '/dev/vdb',
  "cinder_gluster_peers"          => {'server1.example.com' => 'e27f2849-6f69-4900-b348-d7b0ae497509', 'server2.example.com' => '746dc27e-b9bd-46d7-a1a6-7b8957528f4c', 'server3.example.com' => '5fe22c7d-dc85-4d81-8c8b-468876852566'},
  "cinder_gluster_replica_count"  => '3',
  "cinder_gluster_volume"         => 'cinder',
  "cinder_gluster_volume_path"    => '/cinder'
  "cinder_gluster_shares"         => [ '192.168.0.4:/cinder -o backup-volfile-servers=192.168.0.5' ],
  "cinder_nfs_shares"             => [ '192.168.0.4:/cinder' ],
  "cinder_nfs_mount_options"      => '',
  "cinder_san_ip"                 => ['192.168.124.11'],
  "cinder_san_login"              => ['grpadmin'],
  "cinder_san_password"           => [SecureRandom.hex],
  "cinder_san_thin_provision"     => ['false'],
  "cinder_eqlx_group_name"        => ['group-0'],
  "cinder_eqlx_pool"              => ['default'],
  "cinder_eqlx_use_chap"          => ['false'],
  "cinder_eqlx_chap_login"        => ['chapadmin'],
  "cinder_eqlx_chap_password"     => [SecureRandom.hex],
  "cinder_rbd_pool"               => 'volumes',
  "cinder_rbd_ceph_conf"          => '/etc/ceph/ceph.conf',
  "cinder_rbd_flatten_volume_from_snapshot" \
                                  => 'false',
  "cinder_rbd_max_clone_depth"    => '5',
  "cinder_rbd_user"               => 'cinder',
  "cinder_rbd_secret_uuid"        => '',
  "glance_db_password"            => SecureRandom.hex,
  "glance_user_password"          => SecureRandom.hex,
  "glance_gluster_device"         => '/dev/vdc',
  "glance_gluster_peers"          => {'server1.example.com' => 'e27f2849-6f69-4900-b348-d7b0ae497509', 'server2.example.com' => '746dc27e-b9bd-46d7-a1a6-7b8957528f4c', 'server3.example.com' => '5fe22c7d-dc85-4d81-8c8b-468876852566'},
  "glance_gluster_volume"         => 'glance',
  "glance_gluster_volume_path"    => '/glance',
  "glance_gluster_replica_count"  => '3',
  "glance_backend"                => 'file',
  "glance_rbd_store_user"         => 'glance',
  "glance_rbd_store_pool"         => 'images',
  "gluster_open_port_count"       => '10',
  "heat_auth_encryption_key"      => SecureRandom.hex,
  "heat_db_password"              => SecureRandom.hex,
  "heat_user_password"            => SecureRandom.hex,
  "heat_cfn_user_password"        => SecureRandom.hex,
  "heat_auth_encrypt_key"         => SecureRandom.hex,
  "horizon_secret_key"            => SecureRandom.hex,
  "keystone_admin_token"          => SecureRandom.hex,
  "keystone_db_password"          => SecureRandom.hex,
  "keystone_user_password"        => SecureRandom.hex,
  "mysql_root_password"           => SecureRandom.hex,
  "neutron_db_password"           => SecureRandom.hex,
  "neutron_user_password"         => SecureRandom.hex,
  "nova_db_password"              => SecureRandom.hex,
  "nova_user_password"            => SecureRandom.hex,
  "nova_default_floating_pool"    => 'nova',
  "swift_admin_password"          => SecureRandom.hex,
  "swift_gluster_device"          => '/dev/vdd',
  "swift_gluster_peers"           => {'server1.example.com' => 'e27f2849-6f69-4900-b348-d7b0ae497509', 'server2.example.com' => '746dc27e-b9bd-46d7-a1a6-7b8957528f4c', 'server3.example.com' => '5fe22c7d-dc85-4d81-8c8b-468876852566'},
  "swift_gluster_replica_count"   => '3',
  "swift_gluster_volume"          => 'swift',
  "swift_gluster_volume_path"     => '/swift',
  "swift_shared_secret"           => SecureRandom.hex,
  "swift_user_password"           => SecureRandom.hex,
  "swift_all_ips"                 => ['192.168.203.1', '192.168.203.2', '192.168.203.3', '192.168.203.4'],
  "swift_ext4_device"             => '/dev/sdc2',
  "swift_local_interface"         => 'eth3',
  "swift_loopback"                => true,
  "swift_ring_server"             => '192.168.203.1',
  "fixed_network_range"           => '10.0.0.0/24',
  "floating_network_range"        => '10.0.1.0/24',
  "controller_admin_host"         => '172.16.0.1',
  "controller_priv_host"          => '172.16.0.1',
  "controller_pub_host"           => '172.16.1.1',
  "mysql_host"                    => '172.16.0.1',
  "mysql_virtual_ip"              => '192.168.200.220',
  "mysql_bind_address"            => '0.0.0.0',
  "mysql_virt_ip_nic"             => 'eth1',
  "mysql_virt_ip_cidr_mask"       =>  '24',
  "mysql_shared_storage_device"   => '192.168.203.200:/mnt/mysql',
  "mysql_shared_storage_type"     => 'nfs',
  "mysql_shared_storage_options"  => '',
  "mysql_resource_group_name"     => 'mysqlgrp',
  "mysql_clu_member_addrs"        => '192.168.203.11 192.168.203.12 192.168.203.13',
  "amqp_provider"                 => 'rabbitmq',
  "amqp_host"                     => '172.16.0.1',
  "amqp_username"                 => 'openstack',
  "amqp_password"                 => SecureRandom.hex,
  "admin_email"                   => "admin@#{Facter.value(:domain)}",
  "neutron_metadata_proxy_secret" => SecureRandom.hex,
  "enable_ovs_agent"              => "true",
  "ovs_vlan_ranges"               => '',
  "ovs_bridge_mappings"           => [],
  "ovs_bridge_uplinks"            => [],
  "tenant_network_type"           => 'vxlan',
  "enable_tunneling"              => 'True',
  "ovs_vxlan_udp_port"            => '4789',
  "ovs_tunnel_types"              => ['vxlan'],
  "auto_assign_floating_ip"       => 'True',
  "cisco_vswitch_plugin"          => 'neutron.plugins.openvswitch.ovs_neutron_plugin.OVSNeutronPluginV2',
  "cisco_nexus_plugin"            => 'neutron.plugins.cisco.nexus.cisco_nexus_plugin_v2.NexusPlugin',
  "nexus_config"                  => {},
  "nexus_credentials"             => [],
  "provider_vlan_auto_create"     => "false",
  "provider_vlan_auto_trunk"      => "false",
  "backend_server_names"          => [],
  "backend_server_addrs"          => [],
  "lb_backend_server_names"       => [],
  "lb_backend_server_addrs"       => [],
  "configure_ovswitch"            => "true",
  "neutron"                       => "false",
  "ssl"                           => "false",
  "freeipa"                       => "false",
  "mysql_ca"                      => "/etc/ipa/ca.crt",
  "mysql_cert"                    => "/etc/pki/tls/certs/PRIV_HOST-mysql.crt",
  "mysql_key"                     => "/etc/pki/tls/private/PRIV_HOST-mysql.key",
  "amqp_ca"                       => "/etc/ipa/ca.crt",
  "amqp_cert"                     => "/etc/pki/tls/certs/PRIV_HOST-amqp.crt",
  "amqp_key"                      => "/etc/pki/tls/private/PRIV_HOST-amqp.key",
  "horizon_ca"                    => "/etc/ipa/ca.crt",
  "horizon_cert"                  => "/etc/pki/tls/certs/PUB_HOST-horizon.crt",
  "horizon_key"                   => "/etc/pki/tls/private/PUB_HOST-horizon.key",
  "amqp_nssdb_password"           => SecureRandom.hex,
  "fence_xvm_key_file_password"   => SecureRandom.hex,
  "secret_key"                    => SecureRandom.hex,
  "admin_token"                   => SecureRandom.hex,
  "galera_bootstrap"              => false,
  "galera_monitor_username"       => "monitor_user",
  "galera_monitor_password"       => SecureRandom.hex,
  "wsrep_cluster_name"            => "galera_cluster",
  "wsrep_cluster_members"         => ['192.168.203.11', '192.168.203.12', '192.168.203.13'],
  "wsrep_sst_method"              => "rsync",
  "wsrep_sst_username"            => "sst_user",
  "wsrep_sst_password"            => SecureRandom.hex,
  "wsrep_ssl"                     => true,
  "wsrep_ssl_key"                 => "/etc/pki/galera/galera.key",
  "wsrep_ssl_cert"                => "/etc/pki/galera/galera.crt",
}

hostgroups = [
    {:name=>"Controller (Nova Network)",
     :class=>"quickstack::nova_network::controller"},
    {:name=>"Compute (Nova Network)",
     :class=>"quickstack::nova_network::compute"},
    {:name=>"Controller (Neutron)",
     :class=>"quickstack::neutron::controller"},
    {:name=>"Compute (Neutron)",
     :class=>"quickstack::neutron::compute"},
    {:name=>"Neutron Networker",
     :class=>"quickstack::neutron::networker"},
    {:name=>"Cinder Block Storage",
     :class=>"quickstack::storage_backend::cinder"},
    {:name=>"Load Balancer",
     :class=>"quickstack::load_balancer"},
    {:name=>"HA Mysql Node",
     :class=>"quickstack::hamysql::node"},
    {:name=>"Swift Storage Node",
     :class=>"quickstack::swift::storage"},
    {:name=>"HA All In One Controller",
     :class=>["quickstack::openstack_common",
              "quickstack::pacemaker::common",
              "quickstack::pacemaker::params",
              "quickstack::pacemaker::keystone",
              "quickstack::pacemaker::swift",
              "quickstack::pacemaker::load_balancer",
              "quickstack::pacemaker::memcached",
              "quickstack::pacemaker::qpid",
              "quickstack::pacemaker::rabbitmq",
              "quickstack::pacemaker::glance",
              "quickstack::pacemaker::nova",
              "quickstack::pacemaker::heat",
              "quickstack::pacemaker::cinder",
              "quickstack::pacemaker::horizon",
              "quickstack::pacemaker::galera",
              "quickstack::pacemaker::neutron",
             ]},
    {:name=>"Gluster Server",
     :class=>["puppet::vardir",
              "quickstack::gluster::server",
             ]},
    {:name=>"Galera Server",
     :class=>"quickstack::galera::server"}
]

def get_key_type(value)
  key_list = LookupKey::KEY_TYPES
  value_type = value.class.to_s.downcase
  if key_list.include?(value_type)
   value_type
  elsif [FalseClass, TrueClass].include? value.class
    'boolean'
  end
  # If we need to handle actual number classes like Fixnum, add those here
end

def set_all_params_override
  pclasses = Puppetclass.find :all
  pclasses.each do |pclass|
    pclass.class_params.each do |p|
      p.override = true
      p.save
    end
  end
end

set_all_params_override

hostgroups.each do |hg|
  pclassnames = hg[:class].kind_of?(Array) ? hg[:class] : [ hg[:class] ]
  pclassnames.each do |pclassname|
    pclass = Puppetclass.find_by_name pclassname
    pclass.class_params.each do |p|
      if params.include?(p.key)
        p.key_type = get_key_type(params[p.key])
        p.default_value = params[p.key]
      end
      p.save
    end
  end
end

# Hostgroups
hostgroups.each do |hg|
  h=Hostgroup.find_or_create_by_name hg[:name]
  h.environment = Environment.find_by_name('production')
  if hg[:class].kind_of?(Array) then
    pclass_ary = Array.new
    hg[:class].each do |pclassname|
      pclass_ary.push (Puppetclass.find_by_name(pclassname))
    end
    h.puppetclasses = pclass_ary
  else
    h.puppetclasses = [ Puppetclass.find_by_name(hg[:class])]
  end
  h.save!
end

if ENV["FOREMAN_PROVISIONING"] == "true" then
  hostgroups.each do |hg|
    h=Hostgroup.find_by_name hg[:name]
    h.puppet_proxy    = Feature.find_by_name("Puppet").smart_proxies.first
    h.puppet_ca_proxy = Feature.find_by_name("Puppet CA").smart_proxies.first
    h.os = os
    h.architecture = a
    h.medium = m
    h.ptable = pt
    h.subnet = s
    h.domain = d
    h.save!
  end
end
