
variable "builder_host" {
  type    = string
}

variable "builder_host_username" {
  type    = string
}

variable "builder_host_password" {
  type    = string
}

variable "builder_host_datastore" {
  type    = string
}

variable "builder_host_portgroup" {
  type    = string
}

variable "builder_host_output_dir" {
  type    = string
}

variable "dockerhub_login" {
  type    = string
  default = "${env("DOCKERHUB_LOGIN")}"
}

variable "dockerhub_password" {
  type    = string
  default = "${env("DOCKERHUB_PASSWORD")}"
}

variable "helper_script_folder" {
  type    = string
  default = "/imagegeneration/helpers"
}

variable "image_folder" {
  type    = string
  default = "/imagegeneration"
}

variable "image_os" {
  type    = string
  default = "ubuntu20"
}

variable "image_version" {
  type    = string
  default = "dev-esxi"
}

variable "imagedata_file" {
  type    = string
  default = "/imagegeneration/imagedata.json"
}

variable "installer_script_folder" {
  type    = string
  default = "/imagegeneration/installers"
}

variable "iso_local_path" {
  type    = string
}

variable "iso_checksum" {
  type    = string
}

variable "numvcpus" {
  type    = string
  default = "4"
}

variable "ovftool_deploy_vcenter" {
  type    = string
}

variable "ovftool_deploy_vcenter_username" {
  type    = string
}

variable "ovftool_deploy_vcenter_password" {
  type    = string
}

variable "ramsize" {
  type    = string
  default = "16384"
}

variable "run_validation_diskspace" {
  type    = string
  default = "false"
}

variable "vm_name" {
  type    = string
}

source "vmware-iso" "ubuntu" {
  boot_command            = [
    "<esc><wait>",
    "<esc><wait>",
    "<enter><wait>",
    "/install/vmlinuz",
    " auto=true",
    " url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg",
    " locale=en_US<wait>",
    " console-setup/ask_detect=false<wait>",
    " console-setup/layoutcode=us<wait>",
    " console-setup/modelcode=pc105<wait>",
    " debconf/frontend=noninteractive<wait>",
    " debian-installer=en_US<wait>",
    " fb=false<wait>",
    " initrd=/install/initrd.gz<wait>",
    " kbd-chooser/method=us<wait>",
    " keyboard-configuration/layout=USA<wait>",
    " keyboard-configuration/variant=USA<wait>",
    " hostname={{ .Name }}<wait>",
    " grub-installer/bootdev=/dev/sda<wait>",
    " noapic<wait>",
    " -- <wait>",
    "<enter><wait>"
  ]
  boot_wait               = "10s"
  cpus                    = "${var.numvcpus}"
  disk_size               = "122880"
  format                  = "ovf"
  guest_os_type           = "ubuntu-64"
  headless                = false
  http_directory          = "${path.root}/http"
  insecure_connection     = true
  iso_checksum            = "${var.iso_checksum}"
  iso_urls                = [
    "${var.iso_local_path}",
    "http://cdimage.ubuntu.com/ubuntu-legacy-server/releases/20.04.1/release/ubuntu-20.04.1-legacy-server-amd64.iso"
  ]
  memory                  = "${var.ramsize}"
  network                 = "vmxnet3"
  network_name            = "${var.builder_host_portgroup}"
  remote_datastore        = "${var.builder_host_datastore}"
  remote_host             = "${var.builder_host}"
  remote_output_directory = "${var.builder_host_output_dir}/build/${var.image_version}"
  remote_password         = "${var.builder_host_password}"
  remote_type             = "esx5"
  remote_username         = "${var.builder_host_username}"
  shutdown_command        = "sudo shutdown -P now"
  shutdown_timeout        = "1000s"
  ssh_password            = "agent"
  ssh_port                = 22
  ssh_username            = "agent"
  ssh_wait_timeout        = "1800s"
  vm_name                 = "${var.vm_name}"
  vmx_data = {
    "ethernet0.addressType"    = "generated"
    "ethernet0.present"        = "TRUE"
    "ethernet0.startConnected" = "TRUE"
    "ethernet0.wakeOnPcktRcv"  = "FALSE"
  }
  vnc_over_websocket = true
}

build {
  sources = ["source.vmware-iso.ubuntu"]

  provisioner "shell" {
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    inline          = [
      "mkdir ${var.image_folder}",
      "chmod 777 ${var.image_folder}"
    ]
  }

  provisioner "shell" {
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    script          = "${path.root}/scripts/base/apt-mock.sh"
  }

  provisioner "shell" {
    environment_vars = ["DEBIAN_FRONTEND=noninteractive"]
    execute_command  = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = ["${path.root}/scripts/base/repos.sh"]
  }

  provisioner "shell" {
    environment_vars = ["DEBIAN_FRONTEND=noninteractive"]
    execute_command  = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    script           = "${path.root}/scripts/base/apt.sh"
  }

  provisioner "shell" {
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    script          = "${path.root}/scripts/base/limits.sh"
  }

  provisioner "file" {
    destination = "${var.helper_script_folder}"
    source      = "${path.root}/scripts/helpers"
  }

  provisioner "file" {
    destination = "${var.installer_script_folder}"
    source      = "${path.root}/scripts/installers"
  }

  provisioner "file" {
    destination = "${var.image_folder}"
    source      = "${path.root}/post-generation"
  }

  provisioner "file" {
    destination = "${var.image_folder}"
    source      = "${path.root}/scripts/tests"
  }

  provisioner "file" {
    destination = "${var.image_folder}"
    source      = "${path.root}/scripts/SoftwareReport"
  }

  provisioner "file" {
    destination = "${var.installer_script_folder}/toolset.json"
    source      = "${path.root}/toolsets/toolset-2004.json"
  }

  provisioner "shell" {
    environment_vars = [
      "IMAGE_VERSION=${var.image_version}",
      "IMAGEDATA_FILE=${var.imagedata_file}"
    ]
    execute_command  = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = ["${path.root}/scripts/installers/preimagedata.sh"]
  }

  provisioner "shell" {
    environment_vars = [
      "IMAGE_VERSION=${var.image_version}",
      "IMAGE_OS=${var.image_os}",
      "HELPER_SCRIPTS=${var.helper_script_folder}"
    ]
    execute_command  = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = ["${path.root}/scripts/installers/configure-environment.sh"]
  }

  provisioner "shell" {
    environment_vars = ["HELPER_SCRIPTS=${var.helper_script_folder}"]
    execute_command  = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = ["${path.root}/scripts/installers/complete-snap-setup.sh"]
  }

  provisioner "shell" {
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    scripts         = ["${path.root}/scripts/installers/powershellcore.sh"]
  }

  provisioner "shell" {
    environment_vars = [
      "HELPER_SCRIPTS=${var.helper_script_folder}",
      "INSTALLER_SCRIPT_FOLDER=${var.installer_script_folder}"
    ]
    execute_command  = "sudo sh -c '{{ .Vars }} pwsh -f {{ .Path }}'"
    scripts          = [
      "${path.root}/scripts/installers/Install-PowerShellModules.ps1",
      "${path.root}/scripts/installers/Install-AzureModules.ps1"
    ]
  }

  provisioner "shell" {
    environment_vars = [
      "HELPER_SCRIPTS=${var.helper_script_folder}",
      "INSTALLER_SCRIPT_FOLDER=${var.installer_script_folder}",
      "DOCKERHUB_LOGIN=${var.dockerhub_login}",
      "DOCKERHUB_PASSWORD=${var.dockerhub_password}"]
    execute_command  = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = [
      "${path.root}/scripts/installers/docker-compose.sh",
      "${path.root}/scripts/installers/docker-moby.sh"
    ]
  }

  provisioner "shell" {
    environment_vars = [
      "HELPER_SCRIPTS=${var.helper_script_folder}",
      "INSTALLER_SCRIPT_FOLDER=${var.installer_script_folder}",
      "DEBIAN_FRONTEND=noninteractive"
    ]
    execute_command  = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = [
      "${path.root}/scripts/installers/azcopy.sh",
      "${path.root}/scripts/installers/azure-cli.sh",
      "${path.root}/scripts/installers/azure-devops-cli.sh",
      "${path.root}/scripts/installers/basic.sh",
      "${path.root}/scripts/installers/aliyun-cli.sh",
      "${path.root}/scripts/installers/apache.sh",
      "${path.root}/scripts/installers/aws.sh",
      "${path.root}/scripts/installers/clang.sh",
      "${path.root}/scripts/installers/swift.sh",
      "${path.root}/scripts/installers/cmake.sh",
      "${path.root}/scripts/installers/codeql-bundle.sh",
      "${path.root}/scripts/installers/containers.sh",
      "${path.root}/scripts/installers/dotnetcore-sdk.sh",
      "${path.root}/scripts/installers/erlang.sh",
      "${path.root}/scripts/installers/firefox.sh",
      "${path.root}/scripts/installers/gcc.sh",
      "${path.root}/scripts/installers/gfortran.sh",
      "${path.root}/scripts/installers/git.sh",
      "${path.root}/scripts/installers/github-cli.sh",
      "${path.root}/scripts/installers/google-chrome.sh",
      "${path.root}/scripts/installers/google-cloud-sdk.sh",
      "${path.root}/scripts/installers/haskell.sh",
      "${path.root}/scripts/installers/heroku.sh",
      "${path.root}/scripts/installers/hhvm.sh",
      "${path.root}/scripts/installers/java-tools.sh",
      "${path.root}/scripts/installers/kubernetes-tools.sh",
      "${path.root}/scripts/installers/oc.sh",
      "${path.root}/scripts/installers/leiningen.sh",
      "${path.root}/scripts/installers/mercurial.sh",
      "${path.root}/scripts/installers/miniconda.sh",
      "${path.root}/scripts/installers/mono.sh",
      "${path.root}/scripts/installers/mysql.sh",
      "${path.root}/scripts/installers/mssql-cmd-tools.sh",
      "${path.root}/scripts/installers/nginx.sh",
      "${path.root}/scripts/installers/nvm.sh",
      "${path.root}/scripts/installers/nodejs.sh",
      "${path.root}/scripts/installers/bazel.sh",
      "${path.root}/scripts/installers/oras-cli.sh",
      "${path.root}/scripts/installers/phantomjs.sh",
      "${path.root}/scripts/installers/php.sh",
      "${path.root}/scripts/installers/postgresql.sh",
      "${path.root}/scripts/installers/pulumi.sh",
      "${path.root}/scripts/installers/ruby.sh",
      "${path.root}/scripts/installers/r.sh",
      "${path.root}/scripts/installers/rust.sh",
      "${path.root}/scripts/installers/julia.sh",
      "${path.root}/scripts/installers/sbt.sh",
      "${path.root}/scripts/installers/selenium.sh",
      "${path.root}/scripts/installers/terraform.sh",
      "${path.root}/scripts/installers/packer.sh",
      "${path.root}/scripts/installers/vcpkg.sh",
      "${path.root}/scripts/installers/dpkg-config.sh",
      "${path.root}/scripts/installers/mongodb.sh",
      "${path.root}/scripts/installers/android.sh",
      "${path.root}/scripts/installers/pypy.sh",
      "${path.root}/scripts/installers/python.sh",
      "${path.root}/scripts/installers/graalvm.sh"
    ]
  }

  provisioner "shell" {
    environment_vars = [
      "HELPER_SCRIPTS=${var.helper_script_folder}",
      "INSTALLER_SCRIPT_FOLDER=${var.installer_script_folder}"]
    execute_command  = "sudo sh -c '{{ .Vars }} pwsh -f {{ .Path }}'"
    scripts          = [
      "${path.root}/scripts/installers/Install-Toolset.ps1",
      "${path.root}/scripts/installers/Configure-Toolset.ps1"
    ]
  }

  provisioner "shell" {
    environment_vars = [
      "HELPER_SCRIPTS=${var.helper_script_folder}",
      "INSTALLER_SCRIPT_FOLDER=${var.installer_script_folder}"]
    execute_command  = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = ["${path.root}/scripts/installers/pipx-packages.sh"]
  }

  provisioner "shell" {
    environment_vars = [
      "HELPER_SCRIPTS=${var.helper_script_folder}",
      "DEBIAN_FRONTEND=noninteractive",
      "INSTALLER_SCRIPT_FOLDER=${var.installer_script_folder}"
    ]
    execute_command  = "/bin/sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = ["${path.root}/scripts/installers/homebrew.sh"]
  }

  provisioner "shell" {
    environment_vars = [
      "HELPER_SCRIPTS=${var.helper_script_folder}",
      "DEBIAN_FRONTEND=noninteractive",
      "INSTALLER_SCRIPT_FOLDER=${var.installer_script_folder}"
    ]
    execute_command  = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = [
      "${path.root}/scripts/installers/vmware.sh",
      "${path.root}/scripts/installers/vsts-agent.sh",
      "${path.root}/scripts/installers/cloud-init.sh"
    ]
  }

  provisioner "shell" {
    execute_command   = "sudo /bin/sh -c '{{ .Vars }} {{ .Path }}'"
    expect_disconnect = true
    scripts           = ["${path.root}/scripts/base/reboot.sh"]
  }

  provisioner "shell" {
    execute_command     = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    pause_before        = "1m0s"
    scripts             = ["${path.root}/scripts/installers/cleanup.sh"]
    start_retry_timeout = "10m"
  }

  provisioner "shell" {
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    script          = "${path.root}/scripts/base/apt-mock-remove.sh"
  }

  provisioner "shell" {
    environment_vars = [
      "IMAGE_VERSION=${var.image_version}",
      "INSTALLER_SCRIPT_FOLDER=${var.installer_script_folder}"]
    inline           = [
      "pwsh -File ${var.image_folder}/SoftwareReport/SoftwareReport.Generator.ps1 -OutputDirectory ${var.image_folder}",
      "pwsh -File ${var.image_folder}/tests/RunAll-Tests.ps1 -OutputDirectory ${var.image_folder}"
    ]
  }

  provisioner "file" {
    destination = "${path.root}/Ubuntu2004-README.md"
    direction   = "download"
    source      = "${var.image_folder}/Ubuntu-Readme.md"
  }

  provisioner "shell" {
    environment_vars = [
      "HELPER_SCRIPT_FOLDER=${var.helper_script_folder}",
      "INSTALLER_SCRIPT_FOLDER=${var.installer_script_folder}",
      "IMAGE_FOLDER=${var.image_folder}"
    ]
    execute_command  = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = ["${path.root}/scripts/installers/post-deployment.sh"]
  }

  provisioner "shell" {
    environment_vars = ["RUN_VALIDATION=${var.run_validation_diskspace}"]
    scripts          = ["${path.root}/scripts/installers/validate-disk-space.sh"]
  }

  provisioner "file" {
    destination = "/tmp/"
    source      = "${path.root}/config/ubuntu2004.conf"
  }

  provisioner "shell" {
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    inline          = ["mkdir -p /etc/vsts", "cp /tmp/ubuntu2004.conf /etc/vsts/machine_instance.conf"]
  }

  post-processor "shell-local" {
    inline = ["pwsh -Command '${path.root}/scripts/esxi/unregister_vm.ps1 -VCenterServerHostName \"${var.ovftool_deploy_vcenter}\" -VCenterUserName \"${var.ovftool_deploy_vcenter_username}\" -VCenterPassword \"${var.ovftool_deploy_vcenter_password}\" -VMName \"${var.vm_name}\"'"]
  }
}
