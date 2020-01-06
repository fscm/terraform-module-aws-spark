#
# Terraform module to create an Apache Spark cluster.
#
# Copyright 2016-2020, Frederico Martins
#   Author: Frederico Martins <http://github.com/fscm>
#
# SPDX-License-Identifier: MIT
#
# This program is free software. You can use it and/or modify it under the
# terms of the MIT License.
#

#
# Apache Spark instance(s).
#

resource "aws_instance" "master" {
  count                       = "${var.number_of_masters}"
  ami                         = "${var.ami_id}"
  associate_public_ip_address = "${var.associate_public_ip_address}"
  instance_type               = "${var.spark_master_instance_type}"
  key_name                    = "${var.keyname}"
  subnet_id                   = "${element(var.subnet_ids, count.index - 1)}"
  user_data                   = "${element(data.template_file.master.*.rendered, count.index)}"
  vpc_security_group_ids      = ["${aws_security_group.spark.id}","${aws_security_group.spark_intra.id}","${var.extra_security_group_id}"]
  root_block_device {
    volume_size = "${var.spark_master_root_volume_size}"
    volume_type = "${var.spark_master_root_volume_type}"
    iops        = "${var.spark_master_root_volume_iops}"
  }
  tags {
    Name    = "${var.prefix}${var.name}-master${format("%02d", count.index + 1)}"
    Spark   = "true"
    Service = "Spark Master"
  }
}

data "template_file" "master" {
  count    = "${var.number_of_masters}"
  template = "${file("${path.module}/templates/cloud-config/init.tpl")}"
  vars {
    domain              = "${var.domain}"
    hostname            = "${var.prefix}${var.name}-master${format("%02d", count.index + 1)}"
    spark_args          = "${var.spark_master_heap_size == "" ? var.spark_master_heap_size : "-m var.spark_master_heap_size"}"
    spark_instance_type = "master"
  }
}

resource "aws_launch_configuration" "worker" {
  associate_public_ip_address = "${var.associate_public_ip_address}"
  image_id                    = "${var.ami_id}"
  instance_type               = "${var.spark_worker_instance_type}"
  key_name                    = "${var.keyname}"
  name_prefix                 = "${var.prefix}${var.name}-worker-"
  security_groups             = ["${aws_security_group.spark.id}","${aws_security_group.spark_intra.id}","${var.extra_security_group_id}"]
  user_data                   = "${data.template_file.worker.rendered}"
  lifecycle {
    create_before_destroy = true
  }
  root_block_device {
    volume_size = "${var.spark_worker_root_volume_size}"
    volume_type = "${var.spark_worker_root_volume_type}"
    iops        = "${var.spark_worker_root_volume_iops}"
  }
}

resource "aws_autoscaling_group" "worker" {
  depends_on                = ["aws_launch_configuration.worker"]
  health_check_grace_period = 600
  health_check_type         = "EC2"
  launch_configuration      = "${aws_launch_configuration.worker.name}"
  max_size                  = "${var.spark_worker_max_instances}"
  min_size                  = "${var.spark_worker_min_instances}"
  name                      = "${var.prefix}${var.name}-worker"
  termination_policies      = ["OldestInstance"]
  vpc_zone_identifier       = ["${var.subnet_ids}"]
  lifecycle {
    create_before_destroy = true
  }
  tag {
    key                 = "Name"
    value               = "${var.prefix}${var.name}-worker"
    propagate_at_launch = true
  }
  tag {
    key                 = "Spark"
    value               = "true"
    propagate_at_launch = true
  }
  tag {
    key                 = "Service"
    value               = "Spark Worker"
    propagate_at_launch = true
  }
}

data "template_file" "worker" {
  template = "${file("${path.module}/templates/cloud-config/init.tpl")}"
  vars {
    domain              = "${var.domain}"
    hostname            = "${var.prefix}${var.name}-worker"
    spark_args          = "${var.spark_worker_heap_size == "" ? var.spark_worker_heap_size : "-m var.spark_worker_heap_size"} -s ${var.private_zone_id != "" ? element(aws_route53_record.private.*.fqdn, 0) : element(aws_instance.master.*.private_ip, 0)} -W 60"
    spark_instance_type = "worker"
  }
}

#
# Apache Spark Master DNS record(s).
#

resource "aws_route53_record" "private" {
  count   = "${var.private_zone_id != "" ? var.number_of_masters : 0}"
  name    = "${var.prefix}${var.name}-master${format("%02d", count.index + 1)}"
  records = ["${element(aws_instance.master.*.private_ip, count.index)}"]
  ttl     = "${var.ttl}"
  type    = "A"
  zone_id = "${var.private_zone_id}"
}

resource "aws_route53_record" "public" {
  count   = "${var.public_zone_id != "" && var.associate_public_ip_address ? var.number_of_masters : 0}"
  name    = "${var.prefix}${var.name}-master${format("%02d", count.index + 1)}"
  records = ["${element(aws_instance.master.*.public_ip, count.index)}"]
  ttl     = "${var.ttl}"
  type    = "A"
  zone_id = "${var.public_zone_id}"
}

#
# Apache Spark security group(s).
#

resource "aws_security_group" "spark" {
  name   = "${var.prefix}${var.name}"
  vpc_id = "${var.vpc_id}"
  ingress {
    from_port = 4040
    to_port   = 4040
    protocol  = "tcp"
    self      = true
  }
  ingress {
    from_port = 6066
    to_port   = 6066
    protocol  = "tcp"
    self      = true
  }
  ingress {
    from_port = 7077
    to_port   = 7077
    protocol  = "tcp"
    self      = true
  }
  ingress {
    from_port = 8080
    to_port   = 8081
    protocol  = "tcp"
    self      = true
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  lifecycle {
    create_before_destroy = true
  }
  tags {
    Name    = "${var.prefix}${var.name}"
    Spark   = "true"
    Service = "Spark"
  }
}

resource "aws_security_group" "spark_intra" {
  name   = "${var.prefix}${var.name}-intra"
  vpc_id = "${var.vpc_id}"
  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "-1"
    self      = true
  }
  egress {
    from_port = 0
    to_port   = 65535
    protocol  = "-1"
    self      = true
  }
  lifecycle {
    create_before_destroy = true
  }
  tags {
    Name    = "${var.prefix}${var.name}-intra"
    Spark   = "true"
    Service = "Spark"
  }
}
