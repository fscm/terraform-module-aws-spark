#
# Outputs for the Apache Spark terraform module.
#
# Copyright 2016-2019, Frederico Martins
#   Author: Frederico Martins <http://github.com/fscm>
#
# SPDX-License-Identifier: MIT
#
# This program is free software. You can use it and/or modify it under the
# terms of the MIT License.
#

output "master_fqdn" {
  sensitive = false
  value     = ["${aws_route53_record.private.*.fqdn}"]
}

output "master_hostname" {
  sensitive = false
  value     = ["${aws_instance.master.*.private_dns}"]
}

output "master_id" {
  sensitive = false
  value     = ["${aws_instance.master.*.id}"]
}

output "master_ip" {
  sensitive = false
  value     = ["${aws_instance.master.*.private_ip}"]
}

output "security_group" {
  sensitive = false
  value     = "${aws_security_group.spark.id}"
}

output "ssh_key" {
  sensitive = false
  value     = "${var.keyname}"
}
