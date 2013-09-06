#!/usr/bin/env bash
# Create resilient OVS bridge, move IP from physical interface to bridge, attach physical interface

BRIDGE_NAME=$1
PHYSICAL_INTERFACE=$2

# create openvswitch bridge
/usr/bin/ovs-vsctl --may-exist add-br ${BRIDGE_NAME}

# mv physical interface config 
/bin/mv /etc/sysconfig/network-scripts/ifcfg-${PHYSICAL_INTERFACE} /etc/sysconfig/network-scripts/ifcfg-${BRIDGE_NAME}

# unset HWADDR key if exists
/bin/sed -i s/HWADDR=.*// /etc/sysconfig/network-scripts/ifcfg-${BRIDGE_NAME}    

# unset UUID key if exists
/bin/sed -i s/UUID=.*// /etc/sysconfig/network-scripts/ifcfg-${BRIDGE_NAME}

# set bridge name
/bin/sed -i s/DEVICE=.*/DEVICE=${BRIDGE_NAME}/ /etc/sysconfig/network-scripts/ifcfg-${BRIDGE_NAME}

# set bridge type
/bin/sed -i s/TYPE=.*/TYPE=OVSBridge/ /etc/sysconfig/network-scripts/ifcfg-${BRIDGE_NAME}

# set bridge device type
/bin/echo -e "DEVICETYPE=ovs" >> /etc/sysconfig/network-scripts/ifcfg-${BRIDGE_NAME}

# create new physical interface config 
cat > /etc/sysconfig/network-scripts/ifcfg-${PHYSICAL_INTERFACE} <<EOF
DEVICE=$PHYSICAL_INTERFACE
DEVICETYPE=ovs
TYPE=OVSPort
BOOTPROTO=none
OVS_BRIDGE=${BRIDGE_NAME}
ONBOOT=yes
EOF

# switch on bridge and restart network - atomic operation
/usr/bin/ovs-vsctl --may-exist add-port ${BRIDGE_NAME} $PHYSICAL_INTERFACE; service network restart  

