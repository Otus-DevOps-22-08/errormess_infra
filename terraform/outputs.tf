output "external_ip_addresses_app" {
  value = yandex_compute_instance.app[*].network_interface.0.nat_ip_address
}
output "loadbalancer_ip_address" {
  value = yandex_lb_network_load_balancer.lb.listener.*.external_address_spec[0].*.address
}
