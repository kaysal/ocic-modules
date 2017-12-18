
data "terraform_remote_state" "network_data" {
  backend = "local"
  config {
    path = "${var.remote_state_network_data}"
  }
}

data "template_file" "userdata" {
  vars {
    admin_password = "${var.administrator_password}"
  }
  template = <<JSON
{
	"userdata": {
			"enable_rdp": true,
			"administrator_password": "$${admin_password}",
			"pre-bootstrap": {
				"script": [
					"powershell.exe add-windowsfeature web-server -includeallsubfeature",
					"md c:\\SSH"
					]
				}
	}
}
JSON
}

#	ip network public ip reservation
#-----------------------------------
resource "opc_compute_ip_address_reservation" "ks_win_bastion_ip" {
  name = "${var.instance_name}_ip"
  ip_address_pool = "public-ippool"
  #permanent   = true
}

#	storage volume
#-----------------------------------
resource "opc_compute_storage_volume" "ks_win_bastion_bootVol" {
  name        = "${var.instance_name}_bootVol"
  description = "Boot volume for ${var.instance_name}"
  size        = 24
  bootable = "true"
  image_list = "${var.boot_volume_image_list}"
}

#	instances
#-----------------------------------
resource "opc_compute_instance" "ks_win_bastion" {
  name = "${var.instance_name}"
  label = "${var.instance_name}"
  shape = "${var.instance_shape}"
	instance_attributes = "${data.template_file.userdata.rendered}"
  image_list = "${var.boot_volume_image_list}"

  storage {
  volume = "${opc_compute_storage_volume.ks_win_bastion_bootVol.name}"
  index  = 1
  }

  networking_info {
    index = 0
    ip_network = "${data.terraform_remote_state.network_data.bastion_ipnet}"
    ip_address = "${var.ip_address}"
    vnic = "${var.instance_name}_eth0"
    vnic_sets = ["${data.terraform_remote_state.network_data.bastion_vnicset}"]
    nat = ["${opc_compute_ip_address_reservation.ks_win_bastion_ip.name}"]
  }

}
