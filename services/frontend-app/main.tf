# remote state file that contains ACLs,
# security rules, vnicsets, ip prefix sets, security protocols
#-----------------------------------
data "terraform_remote_state" "network_data" {
  backend = "local"
  config {
    path = "${var.remote_state_network_data}"
  }
}

#	ip network public ip reservation
#-----------------------------------
resource "opc_compute_ip_address_reservation" "ks_frontEnd_ip" {
  name = "${var.instance_name}_ip"
  ip_address_pool = "public-ippool"
  #permanent   = true
}

#	storage volume
#-----------------------------------
resource "opc_compute_storage_volume" "ks_frontEnd_storage" {
  name        = "${var.instance_name}_bootVol"
  description = "Boot volume for ${var.instance_name}"
  size        = 12
  bootable = "true"
  image_list = "${var.boot_volume_image_list}"
}

#	instances
#-----------------------------------
resource "opc_compute_instance" "ks_frontEnd" {
  name = "${var.instance_name}"
  label = "${var.instance_name}"
  shape = "${var.instance_shape}"
  image_list = "${var.boot_volume_image_list}"

  instance_attributes = <<JSON
  {
  	"userdata": {
  		"pre-bootstrap": {
  			"script": [
  				"sudo su",
  				"yum -y install httpd",
  				"yum -y install firewalld",
  				"systemctl unmask firewalld",
  				"systemctl enable firewalld",
  				"systemctl start firewalld",
  				"firewall-cmd --permanent --add-port=80/tcp",
  				"firewall-cmd --permanent --add-port=443/tcp",
  				"firewall-cmd --reload",
  				"systemctl start httpd",
  				"systemctl enable httpd",
  				"echo '<html><b>Hello IaaS CSM Team!</b></html>' >> /var/www/html/index.html",
  				"echo 'MY_PROXY_URL='172.16.2.2:8080/'' >> /etc/profile",
  				"echo 'HTTP_PROXY=$MY_PROXY_URL' >> /etc/profile",
  				"echo 'HTTP_PROXY=$MY_PROXY_URL' >> /etc/profile",
  				"echo 'HTTPS_PROXY=$MY_PROXY_URL' >> /etc/profile",
  				"echo 'FTP_PROXY=$MY_PROXY_URL' >> /etc/profile",
  				"echo 'http_proxy=$MY_PROXY_URL' >> /etc/profile",
  				"echo 'https_proxy=$MY_PROXY_URL' >> /etc/profile",
  				"echo 'ftp_proxy=$MY_PROXY_URL' >> /etc/profile",
  				"echo 'export HTTP_PROXY HTTPS_PROXY FTP_PROXY http_proxy https_proxy ftp_proxy' >> /etc/profile",
  				"source /etc/profile"
  			]
  		}
  	}
  }
JSON

  storage {
  volume = "${opc_compute_storage_volume.ks_frontEnd_storage.name}"
  index  = 1
  }

  networking_info {
    index = 0
    ip_network = "${data.terraform_remote_state.network_data.frontEnd_ipnet}"
    ip_address = "10.0.1.2"
    vnic = "${var.instance_name}_eth0"
    vnic_sets = ["${data.terraform_remote_state.network_data.frontEnd_vnicset}"]
    nat = ["${opc_compute_ip_address_reservation.ks_frontEnd_ip.name}"]
  }

  ssh_keys = [
    "${data.terraform_remote_state.network_data.bastion_ssh_public_key}"
  ]

}
