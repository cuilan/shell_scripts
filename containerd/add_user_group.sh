#!/bin/bash

set -e

ctr --version
containerd --version

sudo usermod -aG containerd $USER
