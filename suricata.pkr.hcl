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
  image_name          = "suricata"
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

      #Suricata
      "sudo add-apt-repository -y ppa:oisf/suricata-stable",
      "sudo apt install suricata -y",
      "sudo systemctl enable suricata.service",
      "sudo systemctl stop suricata.service",
      "sudo sed -i 's/community-id: false/community-id: true /g' /etc/suricata/suricata.yaml",
      "sudo bash -c 'printf \"detect-engine:\n - rule-reload: true\" >> /etc/suricata/suricata.yaml'",
      "sudo suricata-update",
      "sudo suricata-update list-sources",
      "sudo suricata -T -c /etc/suricata/suricata.yaml -v",
      "sudo systemctl start suricata.service",
      "sudo systemctl status suricata.service",
      "sudo bash -c 'printf \"<ossec_config> \n <localfile> \n <log_format>json</log_format> \n <location>/var/log/suricata/eve.json</location> \n </localfile> \n </ossec_config>\" >> /var/ossec/etc/ossec.conf'",

      # Clean
      "rm -rf .sudo_as_admin_successful",
    ]
  }
}
