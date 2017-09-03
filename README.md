# Apache Spark Terraform Module

A terraform module to create and manage an Apache Spark cluster on AWS.

## Prerequisites

Terraform and AWS Command Line Interface tools need to be installed on your
local computer.

A previously build AMI base image with Apache Spark is required.

### Terraform

Terraform version 0.8 or higher is required.

Terraform installation instructions can be found
[here](https://www.terraform.io/intro/getting-started/install.html).

### AWS Command Line Interface

AWS Command Line Interface installation instructions can be found [here](http://docs.aws.amazon.com/cli/latest/userguide/installing.html).

### Apache Spark AMI

This module requires that an AMI base image with Apache Spark built using the
recipe from [this](https://github.com/fscm/packer-aws-spark) project to already
exist in your AWS account.

That AMI ID is the one that should be used as the value for the required
`ami_id` variable.

### AWS Route53 Service (optional)

If you wish to register the instances FQDN, the AWS Route53 service is also required to be enabled and properly configured.

To register the instances FQDN on AWS Route53 service you need to set the `private_zone_id` and/or `public_zone_id` variable(s).

## Module Input Variables

- `ami_id` - **[required]** The id of the AMI to use for the instance(s). See the [Apache Spark AMI](#apache-spark-ami) section for more information.
- `associate_public_ip_address` - Associate a public IP address to the Apache Spark Master instance(s). *[default value: false]*
- `domain` - **[required]** The domain name to use for the Apache Spark instance(s).
- `extra_security_group_id` - Extra security group to assign to the Apache Spark instance(s) (e.g.: 'sg-3f983f98'). *[default value: '']*
- `keyname` - **[required]** The SSH key name to use for the Apache Spark instance(s).
- `name` - The main name that will be used for the Apache Spark instance(s). *[default value: 'spark']*
[comment]: # (- `number_of_masters` - Number of Apache Spark Master instances. NOT USED YET." *[default value: 1]*.)
- `prefix` - A prefix to prepend to the Apache Spark instance(s) name. *[default value: '']*
- `private_zone_id` - The ID of the hosted zone for the private DNS record(s). *[default value: '']*
- `public_zone_id` - The ID of the hosted zone for the public DNS record(s). Requires `associate_public_ip_address` to be set to 'true'. *[default value: '']*
- `spark_master_heap_size` - The heap size for the Apache Spark Master instance(s) (e.g.: '1G'). *[default value: '']*
- `spark_master_instance_type` - The type of instance to use for the Apache Spark Master instance(s). *[default value: 't2.small']*
- `spark_master_root_volume_iops` - The amount of provisioned IOPS (for 'io1' type only). *[default value: 0]*
- `spark_master_root_volume_size` - The volume size in gigabytes. *[default value: '8']*
- `spark_master_root_volume_type` - The volume type. Must be one of 'standard' (magnetic), 'gp2' (general purpose SSD), or 'io1' (provisioned IOPS SSD). *[default value: 'gp2']*
- `spark_worker_heap_size` - The heap size for the Apache Spark Worker instance(s) (e.g.: '1G'). *[default value: '']*
- `spark_worker_instance_type` - The type of instance to use for the Apache Spark Worker instance(s). *[default value: 't2.small']*
- `spark_worker_max_instances` - Maximum number of Apache Spark Worker instances in the cluster. *[default value: '1']*
- `spark_worker_min_instances` - "Minimum number of Apache Spark Worker instances in the cluster. *[default value: '1']*
- `spark_worker_root_volume_iops` - The amount of provisioned IOPS (for 'io1' type only). *[default value: 0]*
- `spark_worker_root_volume_size` - The volume size in gigabytes. *[default value: '8']*
- `spark_worker_root_volume_type` - The volume type. Must be one of 'standard' (magnetic), 'gp2' (general purpose SSD), or 'io1' (provisioned IOPS SSD). *[default value: 'gp2']*
- `subnet_ids` - **[required]** List of Subnet IDs to launch the instance(s) in (e.g.: ['subnet-0zfg04s2','subnet-6jm2z54q']).
- `ttl` - The TTL (in seconds) for the DNS record(s). *[default value: '600']*
- `vpc_id` - **[required]** The VPC ID for the security group(s).

## Usage

```hcl
module "my_spark_cluster" {
  source                     = "github.com/fscm/terraform-module-aws-spark"
  ami_id                     = "ami-gxrd5hz0"
  domain                     = "mydomain.tld"
  keyname                    = "my_ssh_key"
  name                       = "spark"
  prefix                     = "mycompany-"
  private_zone_id            = "Z3K95H7K1S3F"
  spark_worker_max_instances = "3"
  spark_worker_min_instances = "2"
  subnet_ids                 = ["subnet-0zfg04s2", "subnet-6jm2z54q"]
  vpc_id                     = "vpc-3f0tb39m"
}
```

## Outputs

- `master_fqdn` - **[type: list]** List of FQDNs of the Apache Spark Master instance(s).
- `master_hostname` - **[type: list]** List of hostnames of the Apache Spark Master instance(s).
- `master_id` - **[type: list]** List of IDs of the Apache Spark Master instance(s).
- `master_ip` - **[type: list]** List of private IP address of the Apache Spark Master instance(s).
- `security_group` - **[type: string]** ID of the security group to be added to every instance that requires access to the Apache Spark Cluster.
- `ssh_key` - **[type: string]** The name of the SSH key used.

## Cluster Access

This modules provides a security group that will allow access to the Apache
Spark cluster instances.

That group will allow access to the following ports to all the AWS EC2
instances that belong to the group:

| Service           | Port   | Protocol |
|:------------------|:------:|:--------:|
| Spark Application | 4040   |    TCP   |
| Spark REST Server | 6066   |    TCP   |
| Spark Master      | 7077   |    TCP   |
| Spark Master UI   | 8080   |    TCP   |
| Spark Worker UI   | 8081   |    TCP   |

If access to other ports (like the SSH port) is required, you can create your
own security group and add it to the Apache Spark cluster instances using the
`extra_security_group_id` variable.

## Contributing

1. Fork it!
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a pull request

Please read the [CONTRIBUTING.md](CONTRIBUTING.md) file for more details on how
to contribute to this project.

## Versioning

This project uses [SemVer](http://semver.org/) for versioning. For the versions
available, see the [tags on this repository](https://github.com/fscm/terraform-module-aws-spark/tags).

## Authors

* **Frederico Martins** - [fscm](https://github.com/fscm)

See also the list of [contributors](https://github.com/fscm/terraform-module-aws-spark/contributors)
who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE)
file for details
