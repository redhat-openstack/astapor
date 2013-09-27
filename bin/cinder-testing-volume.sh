#!/bin/bash

set -eo pipefail

volumes_size="$1"
volumes_file=/var/lib/cinder/cinder-volumes
loop_device=""
volume_group="cinder-volumes"

function main() {
    if volume_group_exists; then
        echo "Volume group '$volume_group' exists, reusing."
        success
    fi

    if [ ! -e "$volumes_file" ]; then
        create_volumes_file
    else
        echo "File '$volumes_file' exists, reusing."
    fi

    loop_device=$(find_loop_device)
    if [ -z "$loop_device" ]; then
        create_loop_device
    else
        echo "Loop device '$loop_device' is mapped to '$volumes_file', reusing."
    fi

    if ! which lvs > /dev/null; then
        yum -y install lvm2
    fi

    # We need to check volume group existence again -- it might appear
    # after creation of loop device, if it has been mapped to it previously.
    if ! volume_group_exists; then
        create_volume_group
        success
    else
        echo "Volume group '$volume_group' exists, reusing."
        success
    fi
}

function create_volumes_file() {
    if [ -e "$volumes_file" ]; then
        fatal "create_volumes_file() called, but the file '$volumes_file' exists."
    fi

    if [ -z "$volumes_size" ]; then
        fatal "You must provide virtual volume group size. (e.g. '5G')"
    fi

    local volumes_dir=$(dirname "$volumes_file")
    if [ ! -d "$volumes_dir" ]; then
        mkdir -p "$volumes_dir"
        echo "Created directory '$volumes_dir'."
    fi

    dd if=/dev/zero of="$volumes_file" bs=1 count=0 seek="$volumes_size"
    echo "Created file '$volumes_file'."
}

function find_loop_device() {
    #  cut this: /dev/loop0: [fd01]:660813 (/usr/lib/cinder/cinder-volumes.raw)
    # into that: /dev/loop0
    # and don't crash the script if some command in the pipe fails
    losetup -a | grep "($volumes_file)" | cut -d' ' -f1 | sed -e 's/:$//'; true
}

function create_loop_device() {
    loop_device=$(losetup --show -f "$volumes_file")
    echo "Created loop device '$loop_device' mapped to '$volumes_file'."
}

function volume_group_exists() {
    return $(vgs | sed -e 's/^ *//' | grep "$volume_group " > /dev/null; echo $?)
}

function create_volume_group() {
    pvcreate "$loop_device"
    vgcreate "$volume_group" "$loop_device"
    echo "Created volume group '$volume_group' mapped to '$loop_device'."
}

function fatal() {
    echo "$1"
    exit 1
}

function success() {
    echo "DONE."
    exit 0
}

main
