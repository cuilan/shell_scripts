#!/bin/bash

set -e

CONTAINERD_VERSION="1.7.25"
RUNC_VERSION="1.2.6"


CONTAINERD_RELEASE="https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz"
RUNC_RELEASE="https://github.com/opencontainers/runc/releases/download/v${RUNC_VERSION}/runc.amd64"

tar Cxzvf /usr/local containerd-1.6.2-linux-amd64.tar.gz

function install_containerd() {
    # 下载 containerd
    echo "Downloading containerd v${CONTAINERD_VERSION}..."
    if [ ! -f /usr/local/bin/containerd ]; then
        curl -LO "${CONTAINERD_RELEASE}"
        tar Cxzvf /usr/local containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz
    fi
}

function systemd_containerd() {
    touch /usr/local/lib/systemd/system/containerd.service
    cat > /usr/local/lib/systemd/system/containerd.service << EOF
# Copyright The containerd Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target dbus.service

[Service]
ExecStartPre=-/sbin/modprobe overlay
ExecStart=/usr/local/bin/containerd

Type=notify
Delegate=yes
KillMode=process
Restart=always
RestartSec=5

# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNPROC=infinity
LimitCORE=infinity

# Comment TasksMax if your systemd version does not supports it.
# Only systemd 226 and above support this version.
TasksMax=infinity
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable --now containerd.service
}

function install_runc() {
    if [ ! -f /usr/local/sbin/runc ]; then
        curl -fsSL ${RUNC_RELEASE} >runc.amd64
        install -m 755 runc.amd64 /usr/local/sbin/runc
    fi
}


install_containerd
systemd_containerd
install_runc