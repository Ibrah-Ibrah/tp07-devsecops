packer {
  required_plugins {
    docker = {
      version = ">= 1.0.8"
      source  = "github.com/hashicorp/docker"
    }
  }
}

variable "base_image" {
  description = "Image de base Ubuntu"
  default     = "ubuntu:20.04"
}

variable "image_name" {
  description = "Nom de l'image de sortie"
  default     = "ubuntu-cis"
}

variable "image_tag" {
  description = "Tag de l'image de sortie"
  default     = "latest"
}

source "docker" "ubuntu_cis" {
  image  = var.base_image
  commit = true
  changes = [
    "LABEL cis.level=1",
    "LABEL cis.benchmark=CIS_Ubuntu_22.04_v1.0.0",
    "LABEL maintainer=tp07-devsecops",
  ]
}

build {
  name    = "ubuntu-cis"
  sources = ["source.docker.ubuntu_cis"]

  # Étape 1 : installer Python3 et Ansible dans le conteneur
  provisioner "shell" {
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive",
      "TZ=Europe/Paris",
    ]
    inline = [
      "apt-get update -qq",
      "apt-get install -y -qq python3 python3-apt ansible",
    ]
  }

  # Étape 2 : créer le répertoire cible et copier le playbook Ansible
  provisioner "shell" {
    inline = ["mkdir -p /tmp/ansible"]
  }

  provisioner "file" {
    source      = "${path.root}/ansible/"
    destination = "/tmp/ansible"
  }

  # Étape 3 : exécuter le playbook de durcissement CIS L1
  provisioner "shell" {
    environment_vars = [
      "ANSIBLE_FORCE_COLOR=1",
      "ANSIBLE_HOST_KEY_CHECKING=False",
    ]
    inline = [
      "cd /tmp/ansible",
      "ansible-playbook -i 'localhost,' -c local playbook.yml -v",
    ]
  }

  # Étape 4 : nettoyage des outils de provisionnement
  provisioner "shell" {
    environment_vars = ["DEBIAN_FRONTEND=noninteractive"]
    inline = [
      "apt-get remove -y ansible python3-apt",
      "apt-get autoremove -y",
      "apt-get clean",
      "rm -rf /var/lib/apt/lists/* /tmp/ansible /root/.cache /root/.local",
    ]
  }

  post-processor "docker-tag" {
    repository = var.image_name
    tags       = [var.image_tag]
  }
}
