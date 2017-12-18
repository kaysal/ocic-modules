
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
resource "opc_compute_ip_address_reservation" "ks_FProxy_ip" {
  name = "${var.instance_name}_ip"
  ip_address_pool = "public-ippool"
  #permanent   = true
}

#	storage volume
#-----------------------------------
resource "opc_compute_storage_volume" "ks_FProxy_storage" {
  name        = "${var.instance_name}_bootVol"
  description = "Boot volume for ${var.instance_name}"
  size        = 12
  bootable = "true"
  image_list = "${var.boot_volume_image_list}"
}

#	instances
#-----------------------------------
resource "opc_compute_instance" "ks_FProxy" {
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
  				"yum -y install httpd mod_ssl",
  				"systemctl unmask firewalld",
  				"systemctl enable firewalld",
  				"systemctl start firewalld",
  				"firewall-cmd --permanent --add-port=80/tcp",
  				"firewall-cmd --permanent --add-port=8080/tcp",
  				"firewall-cmd --permanent --add-port=443/tcp",
          "firewall-cmd --permanent --add-port=20/tcp",
          "firewall-cmd --permanent --add-port=21/tcp",
  				"firewall-cmd --reload",
  				"systemctl start httpd",
  				"systemctl enable httpd",
          "echo 'listen 172.16.2.2:8080' >> /etc/httpd/conf.d/frd-proxy.conf",
  				"echo 'ProxyRequests On' >> /etc/httpd/conf.d/frd-proxy.conf",
  				"echo 'ProxyVia On' >> /etc/httpd/conf.d/frd-proxy.conf",
          "echo 'AllowCONNECT 443' >> /etc/httpd/conf.d/frd-proxy.conf",
          "echo '<Proxy *>' >> /etc/httpd/conf.d/frd-proxy.conf",
          "echo 'Require local' >> /etc/httpd/conf.d/frd-proxy.conf",
          "echo 'Require ip 10.0.1.0/24' >> /etc/httpd/conf.d/frd-proxy.conf",
          "echo 'Require ip 192.168.1.128/25' >> /etc/httpd/conf.d/frd-proxy.conf",
          "echo '</Proxy>' >> /etc/httpd/conf.d/frd-proxy.conf",
          "echo '<html><b>APACHE FORWARD PROXY by Kayode Salawu</b></html>' >> /var/www/html/index.html",
  				"systemctl restart httpd"
  			]
  		}
  	}
  }
JSON

  storage {
  volume = "${opc_compute_storage_volume.ks_FProxy_storage.name}"
  index  = 1
  }

  networking_info {
    index = 0
    ip_network = "${data.terraform_remote_state.network_data.FProxy_ipnet}"
    ip_address = "172.16.2.2"
    vnic = "${var.instance_name}_eth0"
    vnic_sets = ["${data.terraform_remote_state.network_data.FProxy_vnicset}"]
    nat = ["${opc_compute_ip_address_reservation.ks_FProxy_ip.name}"]
  }

  ssh_keys = [
    "${data.terraform_remote_state.network_data.bastion_ssh_public_key}"
  ]

}
