#
# == Class: quicstack::neutron::agent::lbass
#
# Setup neutron Load Balance as a Service agent
#
# === Parameters
#
# [*debug*]
#   (optional) Wether or not enable debug
#   Default to false
#
# [*device_driver*]
#   (optional) device driver
#   Defaults to 'neutron.services.loadbalancer.drivers.haproxy.namespace_driver.HaproxyNSDriver',
#
# [*interface_driver*]
#   (optional) interface driver for either Openvswitch or Linuxbridge
#   OVS => 'neutron.agent.linux.interface.OVSInterfaceDriver'
#   Linuxbridge => 'neutron.agent.linux.interface.BridgeInterfaceDriver'
#   Defaults to OVS driver

class quicstack::neutron::agent::lbass (
$debug            = false,
$device_driver    = 'neutron.services.loadbalancer.drivers.haproxy.namespace_driver.HaproxyNSDriver',
$interface_driver = 'neutron.agent.linux.interface.OVSInterfaceDriver'
)
{
  class { 'neutron::agents::lbaas':
    interface_driver => $interface_driver,
    device_driver    => $device_driver,
    user_group       => 'haproxy',
    debug            => $debug,
  }
}
