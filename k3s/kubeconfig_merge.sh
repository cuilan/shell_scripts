#!/bin/bash

#export KUBECONFIG=~/.kube/config:~/.kube/141.yaml
export KUBECONFIG=~/.kube/141.yaml

kubectl config view --flatten > ~/.kube/config