#!/bin/bash

# Copyright (C) 2019 Intel Corporation
# SPDX-License-Identifier: BSD-3-Clause

set -a

#this is provided while using Utility OS
source /opt/bootstrap/functions



# --- Add Packages
ubuntu_bundles="openssh-server"
ubuntu_packages="wget"

# --- List out any docker images you want pre-installed separated by spaces. ---
pull_sysdockerimagelist=""

# --- List out any docker tar images you want pre-installed separated by spaces.  We be pulled by wget. ---
wget_sysdockerimagelist="" 



# --- Install Extra Packages ---
run "Installing Extra Packages on Ubuntu ${param_ubuntuversion}" \
    "docker run -i --rm --privileged --name ubuntu-installer ${DOCKER_PROXY_ENV} -v /dev:/dev -v /sys/:/sys/ -v $ROOTFS:/target/root ubuntu:${param_ubuntuversion} sh -c \
    'mount --bind dev /target/root/dev && \
    mount -t proc proc /target/root/proc && \
    mount -t sysfs sysfs /target/root/sys && \
    LANG=C.UTF-8 chroot /target/root sh -c \
        \"$(echo ${INLINE_PROXY} | sed "s#'#\\\\\"#g") export TERM=xterm-color && \
        export DEBIAN_FRONTEND=noninteractive && \
        ${MOUNT_DURING_INSTALL} && \
        apt install -y tasksel && \
        tasksel install ${ubuntu_bundles} && \
        apt install -y ${ubuntu_packages}\"'" \
    ${PROVISION_LOG}

# --- Pull any and load any system images ---
for image in $pull_sysdockerimagelist; do
	run "Installing system-docker image $image" "docker exec -i system-docker docker pull $image" "$TMP/provisioning.log"
done
for image in $wget_sysdockerimagelist; do
	run "Installing system-docker image $image" "wget -O- $image 2>> $TMP/provisioning.log | docker exec -i system-docker docker load" "$TMP/provisioning.log"
done

# --- Leave a trace
run "SVEN - leave a trace" "docker exec -i system-docker docker network create sven_net2" "$TMP/provisioning.log"


# --- Start the Portainer edge agent
run "Start the Portainer edge agent" "docker exec -i system-docker \
docker run -d \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /var/lib/docker/volumes:/var/lib/docker/volumes \
    -v /:/host \
    -v portainer_agent_data:/data \
    --restart always \
    -e EDGE=1 \
    -e EDGE_ID=2e203fb4-ade1-4ed8-93cb-a177e51cf4b8 \
    -e EDGE_KEY=aHR0cHM6Ly9wb3J0YWluZXIucDEuYWxoby5zdHxwb3J0YWluZXIucDEuYWxoby5zdDo4MDAwfDQzOmI1OmJlOmE0OjdiOjcyOjRkOjVhOjk4OjA3OmQ3OmUzOjgwOmViOmJkOjgyfDIx \
    -e CAP_HOST_MANAGEMENT=1 \
    -e EDGE_INSECURE_POLL=1 \
    --name portainer_edge_agent \
    portainer/agent:2.9.3" "$TMP/provisioning.log"
