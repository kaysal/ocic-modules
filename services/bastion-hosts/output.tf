
output "ks_win_bastion_Public_IP_Address" {
  value = "${opc_compute_ip_address_reservation.ks_win_bastion_ip.ip_address}"
}
