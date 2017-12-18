output "RProxy_Public_IP_Address" {
  value = "${opc_compute_ip_address_reservation.ks_RProxy_ip.ip_address}"
}
