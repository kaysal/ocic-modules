
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
resource "opc_compute_ip_address_reservation" "ks_RProxy_ip" {
  name = "${var.instance_name}_ip"
  ip_address_pool = "public-ippool"
  #permanent   = true
}

#	storage volume
#-----------------------------------
resource "opc_compute_storage_volume" "ks_RProxy_storage" {
  name        = "${var.instance_name}_bootVol"
  description = "Boot volume for ${var.instance_name}"
  size        = 12
  bootable = "true"
  image_list = "${var.boot_volume_image_list}"
}

#	instances
#-----------------------------------
resource "opc_compute_instance" "ks_RProxy" {
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
         "touch /etc/yum.repos.d/nginx.repo",
         "echo '[nginx]' >> /etc/yum.repos.d/nginx.repo",
         "echo 'name=nginx repo' >> /etc/yum.repos.d/nginx.repo",
         "echo 'baseurl=http://nginx.org/packages/rhel/7/$basearch/' >> /etc/yum.repos.d/nginx.repo",
         "echo 'gpgcheck=0' >> /etc/yum.repos.d/nginx.repo",
         "echo 'enabled=1' >> /etc/yum.repos.d/nginx.repo",
         "yum install nginx -y",
         "service iptables stop",
         "chkconfig iptables off",
         "systemctl start nginx.service",
         "cp /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.backup",
         "rm /etc/nginx/conf.d/default.conf -f",
         "echo '/etc/nginx/conf.d/default.conf' >> /etc/nginx/conf.d/default.conf.backup",
         "echo 'server {' >> /etc/nginx/conf.d/default.conf",
         "echo '    listen 80;' >> /etc/nginx/conf.d/default.conf",
         "echo '    location / {' >> /etc/nginx/conf.d/default.conf",
         "echo '        proxy_pass http://10.0.1.2:80/;' >> /etc/nginx/conf.d/default.conf",
         "echo '    }' >> /etc/nginx/conf.d/default.conf",
         "echo '    error_page   500 502 503 504  /50x.html;' >> /etc/nginx/conf.d/default.conf",
         "echo '    location = /50x.html {' >> /etc/nginx/conf.d/default.conf",
         "echo '        root   /usr/share/nginx/html;' >> /etc/nginx/conf.d/default.conf",
         "echo '    }' >> /etc/nginx/conf.d/default.conf",
         "echo '}' >> /etc/nginx/conf.d/default.conf",
         "service nginx restart"
       ]
     }
   }
  }
JSON

  storage {
  volume = "${opc_compute_storage_volume.ks_RProxy_storage.name}"
  index  = 1
  }

  networking_info {
    index = 0
    ip_network = "${data.terraform_remote_state.network_data.RProxy_ipnet}"
    ip_address = "${var.ip_address}"
    vnic = "${var.instance_name}_eth0"
    vnic_sets = ["${data.terraform_remote_state.network_data.RProxy_vnicset}"]
    nat = ["${opc_compute_ip_address_reservation.ks_RProxy_ip.name}"]
  }

  ssh_keys = [
    "${data.terraform_remote_state.network_data.bastion_ssh_public_key}"
  ]

}
