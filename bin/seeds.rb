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

# for openstack
private_int = 'PRIV_INTERFACE'
public_int  = 'PUB_INTERFACE'

# for the sub-network foreman owns
secondary_int = 'SECONDARY_INT'

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
Setting[:foreman_url] = Facter.fqdn

# Create an OS to assign things to. We'll come back later to finish it's config
os = Operatingsystem.where(:name => "RedHat", :major => "6", :minor => "4").first
os ||= Operatingsystem.create(:name => "RedHat", :major => "6", :minor => "4")
os.type = "Redhat"
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
  # "site" for local Satellite, "hosted" for RHN
  "satellite_type" => "site",
  "satellite_host" => "satellite.example.com",
  # Activation key must have OpenStack child channel
  "activation_key" => "1-example",
}.each do |k,v|
  p=OsParameter.find_or_create_by_name(k)
  p.value = v
  p.reference_id = os.id
  p.save!
end

# Add Proxy
# Figure out how to call this before the class import
# SmartProxy.new(:name => "OpenStack Smart Proxy", :url => "https://#{Facter.fqdn}:8443"

# Architectures
a=Architecture.find_or_create_by_name "x86_64"
a.operatingsystems << os
a.save!

if ENV["FOREMAN_PROVISIONING"] == "true" then
  # Domains
  d=Domain.find_or_create_by_name Facter.domain
  d.fullname="OpenStack: #{Facter.domain}"
  d.dns = Feature.find_by_name("DNS").smart_proxies.first
  d.save!

  # Subnets - use Import Subnet code
  s=Subnet.find_or_create_by_name "OpenStack"
  s.network=Facter.send "network_#{secondary_int}"
  s.mask=Facter.send "netmask_#{secondary_int}"
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
  primary_prefix=Facter.send("network_#{primary_int}").split('.')[0..2].join('.')
  sec_int_hash=Facter.to_hash.reject { |k| k !~ /^ipaddress_/ }.reject { |k| k =~ /lo|#{primary_int}/ }.first
  secondary_int=sec_int_hash[0].split('_').last
  secondary_prefix=sec_int_hash[1].split('.')[0..2].join('.')
end

params = {
  "verbose"                      => "true",
  "heat_cfn"                     => "false",
  "heat_cloudwatch"              => "false",
  "admin_password"               => SecureRandom.hex,
  "ceilometer_metering_secret"   => SecureRandom.hex,
  "ceilometer_user_password"     => SecureRandom.hex,
  "cinder_db_password"           => SecureRandom.hex,
  "cinder_user_password"         => SecureRandom.hex,
  "glance_db_password"           => SecureRandom.hex,
  "glance_user_password"         => SecureRandom.hex,
  "heat_db_password"             => SecureRandom.hex,
  "heat_user_password"           => SecureRandom.hex,
  "horizon_secret_key"           => SecureRandom.hex,
  "keystone_admin_token"         => SecureRandom.hex,
  "keystone_db_password"         => SecureRandom.hex,
  "mysql_root_password"          => SecureRandom.hex,
  "neutron_db_password"          => SecureRandom.hex,
  "neutron_user_password"        => SecureRandom.hex,
  "nova_db_password"             => SecureRandom.hex,
  "nova_user_password"           => SecureRandom.hex,
  "private_interface"            => private_int,
  "public_interface"             => public_int,
  "fixed_network_range"          => 'PRIV_RANGE',
  "floating_network_range"       => 'PUB_RANGE',
  "controller_priv_floating_ip"  => 'PRIV_IP',
  "controller_pub_floating_ip"   => 'PUB_IP',
  "mysql_host"                   => 'PRIV_IP',
  "qpid_host"                    => 'PRIV_IP',
  "admin_email"                  => "admin@#{Facter.domain}",
  "private_ip"                   => "$ipaddress_@#{private_int}",
  "metadata_proxy_shared_secret" => SecureRandom.hex,
  "lb_private_vip"               => '',
  "lb_public_vip"                => '',
  "lb_member_names"              => '',
  "lb_member_addrs"              => '',
  "configure_ovswitch"           => "true",
}

hostgroups = [
    {:name=>"OpenStack Controller",
     :class=>"quickstack::nova_network::controller"},
    {:name=>"OpenStack Nova Compute",
     :class=>"quickstack::nova_network::compute"},
    {:name=>"OpenStack Neutron Controller",
     :class=>"quickstack::neutron::controller "},
    {:name=>"OpenStack Neutron Compute",
     :class=>"quickstack::neutron::compute"},
    {:name=>"OpenStack Neutron Networker",
     :class=>"quickstack::neutron::networker"},
    {:name=>"OpenStack Block Storage",
     :class=>"quickstack::cinder_storage"},
    {:name=>"OpenStack Load Balancer",
     :class=>"quickstack::load_balancer"},
]

hostgroups.each do |hg|
pclass = Puppetclass.find_by_name hg[:class]
  params.each do |k,v|
    p = pclass.class_params.find_by_key(k)
    unless p.nil?
      p.default_value = v
      p.override = true
      p.save
    end
  end
end

# Hostgroups
hostgroups.each do |hg|
  h=Hostgroup.find_or_create_by_name hg[:name]
  h.environment = Environment.find_by_name('production')
  h.puppetclasses = [ Puppetclass.find_by_name(hg[:class])]
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
