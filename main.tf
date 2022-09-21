provider "alicloud" {}

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
  system_disk_size     = 100

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
      "cd /opt/metersphere/",
      "IP=$(hostname -i) && sed -i #s/MS_KAFKA_HOST=.*/MS_KAFKA_HOST=$IP# install.conf",
      "IP=$(hostname -i) && sed -i #s/MS_REDIS_HOST=.*/MS_REDIS_HOST=$IP# install.conf",
      "systemctl start docker && msctl reload",
    ]
  }
}

resource "null_resource" "nc-provisioner" {
  count = var.nc_count
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
      "cd /opt/metersphere/",
      "sed -i 's/MS_INSTALL_MODE=allinone/MS_INSTALL_MODE=node-controller/g' install.conf",
      "systemctl start docker && msctl reload",
    ]
  }
}

module "ms-node-controller" {
  source  = "alibaba/ecs-instance/alicloud"
  profile="default"
  version = "~> 2.0"
  region  = var.region

  number_of_instances = var.nc_count

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
  system_disk_size     = 20

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
