provider "alicloud" {
  profile="default"
}

module "ms-server" {
  source  = "alibaba/ecs-instance/alicloud"
  profile="default"
  version = "~> 2.0"
  region  = var.region

  number_of_instances = 1

  name                        = "ms-server"
  use_num_suffix              = true
  image_id                    = var.image_id
  instance_type               = var.instance_type
  vswitch_id                  = var.vswitch_id
  security_group_ids          = ["${var.sg_id}"]
  associate_public_ip_address = true
  internet_max_bandwidth_out  = 10
  spot_strategy               = "SpotAsPriceGo"

  key_name = var.key_name

  system_disk_category = "cloud_ssd"
  system_disk_size     = 200

  tags = {
    Created      = "Terraform"
    Application  = "MeterSphere"
  }
}

resource "null_resource" "server-provisioner" {
  # Changes to any instance of the cluster requires re-provisioning
  count = 1
  triggers = {
    ms-server_ids = "${join(",", module.ms-server.this_instance_id)}"
  }
  # Bootstrap script can run on any instance of the cluster
  # So we just choose the first in this case
  connection {
    host = "${element(module.ms-server.this_public_ip, 0)}"
    private_key = file("${path.module}/${var.key_name}.pem")
  }

  provisioner "file" {
    source      = "install_metersphere.sh"
    destination = "/tmp/install_metersphere.sh"
  }


  provisioner "remote-exec" {
    # Bootstrap script called with private_ip of each node in the cluster
    inline = [
      "chmod +x /tmp/install_metersphere.sh",
      "/tmp/install_metersphere.sh server ${join(":9092,", module.ms-kafka.this_private_ip)} >/tmp/install_metersphere.log 2>&1",
    ]
  }
}

resource "null_resource" "ds-provisioner" {
  count = 3
  # Changes to any instance of the cluster requires re-provisioning
  triggers = {
    ms-server_ids = "${join(",", module.ms-data-streaming.this_instance_id)}"
  }

  # Bootstrap script can run on any instance of the cluster
  # So we just choose the first in this case
  connection {
    host = "${element(module.ms-data-streaming.this_public_ip, count.index)}"
    private_key = file("${path.module}/${var.key_name}.pem")
  }

  provisioner "file" {
    source      = "install_metersphere.sh"
    destination = "/tmp/install_metersphere.sh"
  }


  provisioner "remote-exec" {
    # Bootstrap script called with private_ip of each node in the cluster
    inline = [
      "chmod +x /tmp/install_metersphere.sh",
      "/tmp/install_metersphere.sh data-streaming ${join(":9092,", module.ms-kafka.this_private_ip)} ${module.ms-server.this_private_ip} >/tmp/install_metersphere.log 2>&1",
    ]
  }
}

resource "null_resource" "nc-provisioner" {
  count = 10
  # Changes to any instance of the cluster requires re-provisioning
  triggers = {
    ms-server_ids = "${join(",", module.ms-node-controller.this_instance_id)}"
  }

  # Bootstrap script can run on any instance of the cluster
  # So we just choose the first in this case
  connection {
    host = "${element(module.ms-node-controller.this_public_ip, count.index)}"
    private_key = file("${path.module}/${var.key_name}.pem")
  }

  provisioner "file" {
    source      = "install_metersphere.sh"
    destination = "/tmp/install_metersphere.sh"
  }


  provisioner "remote-exec" {
    # Bootstrap script called with private_ip of each node in the cluster
    inline = [
      "chmod +x /tmp/install_metersphere.sh",
      "/tmp/install_metersphere.sh node-controller ${join(":9092,", module.ms-kafka.this_private_ip)} >/tmp/install_metersphere.log 2>&1",
    ]
  }
}

resource "null_resource" "kafka-provisioner" {
  count = 3
  # Changes to any instance of the cluster requires re-provisioning
  triggers = {
    ms-server_ids = "${join(",", module.ms-kafka.this_instance_id)}"
  }

  # Bootstrap script can run on any instance of the cluster
  # So we just choose the first in this case
  connection {
    host = "${element(module.ms-kafka.this_public_ip, count.index)}"
    private_key = file("${path.module}/${var.key_name}.pem")
  }

  provisioner "file" {
    source      = "install_kafka.sh"
    destination = "/tmp/install_kafka.sh"
  }


  provisioner "remote-exec" {
    # Bootstrap script called with private_ip of each node in the cluster
    inline = [
      "chmod +x /tmp/install_kafka.sh",
      "/tmp/install_kafka.sh ${count.index} ${join(":2181,", module.ms-kafka.this_private_ip)} >/tmp/install_kafka.log 2>&1",
    ]
  }
}

module "ms-data-streaming" {
  source  = "alibaba/ecs-instance/alicloud"
  profile="default"
  version = "~> 2.0"
  region  = var.region

  number_of_instances = 3

  name                        = "ms-data-streaming"
  use_num_suffix              = true
  image_id                    = var.image_id
  instance_type               = var.instance_type
  vswitch_id                  = var.vswitch_id
  security_group_ids          = ["${var.sg_id}"]
  associate_public_ip_address = true
  internet_max_bandwidth_out  = 10
  spot_strategy               = "SpotAsPriceGo"

  key_name = var.key_name

  system_disk_category = "cloud_ssd"
  system_disk_size     = 100

  tags = {
    Created      = "Terraform"
    Application  = "MeterSphere"
  }
}

module "ms-node-controller" {
  source  = "alibaba/ecs-instance/alicloud"
  profile="default"
  version = "~> 2.0"
  region  = var.region

  number_of_instances = 10

  name                        = "ms-node-controller"
  use_num_suffix              = true
  image_id                    = var.image_id
  instance_type               = var.instance_type
  vswitch_id                  = var.vswitch_id
  security_group_ids          = ["${var.sg_id}"]
  associate_public_ip_address = true
  internet_max_bandwidth_out  = 10
  spot_strategy               = "SpotAsPriceGo"

  key_name = var.key_name

  system_disk_category = "cloud_ssd"
  system_disk_size     = 100

  tags = {
    Created      = "Terraform"
    Application  = "MeterSphere"
  }  
}

module "ms-kafka" {
  source  = "alibaba/ecs-instance/alicloud"
  profile="default"
  version = "~> 2.0"
  region  = var.region

  number_of_instances = 3

  name                        = "ms-kafka"
  use_num_suffix              = true
  image_id                    = var.image_id
  instance_type               = var.instance_type
  vswitch_id                  = var.vswitch_id
  security_group_ids          = ["${var.sg_id}"]
  associate_public_ip_address = true
  internet_max_bandwidth_out  = 10
  spot_strategy               = "SpotAsPriceGo"

  key_name = var.key_name

  system_disk_category = "cloud_ssd"
  system_disk_size     = 300

  tags = {
    Created      = "Terraform"
    Application  = "MeterSphere"
  } 
}

module "nginx" {
  source  = "alibaba/ecs-instance/alicloud"
  profile = "default"
  version = "~> 2.0"
  region  = var.region

  number_of_instances = 1

  name                        = "nginx-sut"
  use_num_suffix              = true
  image_id                    = var.image_id
  instance_type               = var.instance_type
  vswitch_id                  = var.vswitch_id
  security_group_ids          = ["${var.sg_id}"]
  associate_public_ip_address = true
  internet_max_bandwidth_out  = 10
  spot_strategy               = "SpotAsPriceGo"

  key_name = var.key_name

  system_disk_category = "cloud_ssd"
  system_disk_size     = 100

  tags = {
    Created      = "Terraform"
    Application  = "MeterSphere"
  }
}

output "metersphere-public-ip" {
  value = zipmap(module.ms-server.this_public_ip, module.ms-server.this_private_ip)
}

output "node-controller-ip" {
    value = zipmap(module.ms-node-controller.this_public_ip, module.ms-node-controller.this_private_ip)
}

output "data-streaming-ip" {
    value = zipmap(module.ms-data-streaming.this_public_ip, module.ms-data-streaming.this_private_ip)
}

output "kafka-ip" {
    value = zipmap(module.ms-kafka.this_public_ip, module.ms-kafka.this_private_ip)
}

output "nginx-ip" {
    value = zipmap(module.nginx.this_public_ip, module.nginx.this_private_ip)
}