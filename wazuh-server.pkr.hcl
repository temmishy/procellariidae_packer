# Yandex Cloud Toolbox VM Image based on Ubuntu 20.04 LTS
#
# Provisioner docs:
# https://www.packer.io/docs/builders/yandex
#

variable "YC_FOLDER_ID" {
  type = string
  default = env("YC_FOLDER_ID")
}

variable "YC_ZONE" {
  type = string
  default = env("YC_ZONE")
}

variable "YC_SUBNET_ID" {
  type = string
  default = env("YC_SUBNET_ID")
}


source "yandex" "yc-toolbox" {
  folder_id           = "${var.YC_FOLDER_ID}"
  source_image_family = "ubuntu-2004-lts"
  ssh_username        = "ubuntu"
  use_ipv4_nat        = "true"
  image_description   = "Yandex Cloud wazuh image"
  image_family        = "my-images"
  image_name          = "wazuh"
  subnet_id           = "${var.YC_SUBNET_ID}"
  disk_type           = "network-hdd"
  zone                = "${var.YC_ZONE}"
}

build {
  sources = ["source.yandex.yc-toolbox"]

  provisioner "shell" {
    inline = [

      # Docker
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-keyring.gpg",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "sudo apt-get update",
      "sudo apt-get install -y docker-ce containerd.io",
      "sudo usermod -aG docker $USER",
      "sudo chmod 666 /var/run/docker.sock",
      "sudo useradd -m -s /bin/bash -G docker yc-user",
      "sudo apt-get install -y docker-compose",

      # Other packages
      "sudo apt-get install -y git",

      # Wazuh Install
      "git clone https://github.com/wazuh/wazuh-docker.git -b v4.3.10",
      "cd wazuh-docker/single-node",
      "docker-compose -f generate-indexer-certs.yml run --rm generator",
      "docker-compose up -d",

      # Clean
      "rm -rf .sudo_as_admin_successful",
    ]
  }
}
