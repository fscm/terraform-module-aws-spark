#cloud-config
#
# Cloud-Config template for the Apache Spark instances.
#
# Copyright 2016-2019, Frederico Martins
#   Author: Frederico Martins <http://github.com/fscm>
#
# SPDX-License-Identifier: MIT
#

fqdn: ${hostname}.${domain}
hostname: ${hostname}
manage_etc_hosts: true

write_files:
  - content: |
      #!/bin/bash
      echo "=== Setting up Apache Spark Instance ==="
      echo "  instance: ${hostname}.${domain}"
      sudo /usr/local/bin/spark_config ${spark_args} -E -S ${spark_instance_type}
      echo "=== All Done ==="
    path: /tmp/setup_spark.sh
    permissions: '0755'

runcmd:
  - /tmp/setup_spark.sh
  - rm /tmp/setup_spark.sh
