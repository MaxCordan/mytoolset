#!/bin/bash

sudo bash -c "echo \"${USER}  ALL=(ALL) NOPASSWD:ALL\" > /etc/sudoers.d/${USER}"
