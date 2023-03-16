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
  image_description   = "Yandex Cloud Ubuntu Toolbox image"
  image_family        = "my-images"
  image_name          = "tomcat"
  subnet_id           = "${var.YC_SUBNET_ID}"
  disk_type           = "network-hdd"
  zone                = "${var.YC_ZONE}"
}

build {
  sources = ["source.yandex.yc-toolbox"]

  provisioner "shell" {
    inline = [

      # install wazuh packages
      "curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | sudo gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && sudo chmod 644 /usr/share/keyrings/wazuh.gpg",
      "echo \"deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main\" | sudo tee -a /etc/apt/sources.list.d/wazuh.list",
      "sudo apt-get update",
      "WAZUH_MANAGER=\"172.17.17.17\" sudo apt-get install -y wazuh-agent",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable wazuh-agent",
      "sudo sed -i 's/MANAGER_IP/172.17.17.17/g' /var/ossec/etc/ossec.conf",

      # Clean
      "rm -rf .sudo_as_admin_successful",
    ]
  }
}
