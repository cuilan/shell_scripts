#!/bin/bash

K8S_VAERSION=v1.17.4
PAUSE_VERSION=3.1
ECTD_VERSION=3.4.3-0
COREDNS_VERSION=1.6.5

images=(
    kube-apiserver:$(K8S_VAERSION)
    kube-controller-manager:$(K8S_VAERSION)
    kube-scheduler:$(K8S_VAERSION)
    kube-proxy:$(K8S_VAERSION)
    pause:$(PAUSE_VERSION)
    etcd:$(ECTD_VERSION)
    coredns:$(COREDNS_VERSION)
)

for imageName in ${images[@]} ; do
    crictl pull registry.cn-hangzhou.aliyuncs.com/google_containners/$imageName
    crictl tag registry.cn-hangzhou.aliyuncs.com/google_containners/$imageName k8s.gcr.io/$imageName
    crictl rmi registry.cn-hangzhou.aliyuncs.com/google_containners/$imageName
done
