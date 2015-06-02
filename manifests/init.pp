# Class: marathon
#
# This module installs, configures and manages marathon
#
# Parameters: none
#
# Actions:
#
# Requires: see Modulefile
#
# Sample Usage:
#
class marathon(
# Install or uninstall (present|absent)
  $installation_ensure      = 'present',
# Marathon binary url
  $url                      = 'https://downloads.mesosphere.io/marathon/v0.8.2-RC4/marathon-0.8.2-RC4.tgz',
# Marathon binary digest string
  $digest_string            = '7159bd327a6b7ad7dd7e92bb490fc1cc229bc5f799f34a91da7b9e60a42454c3',
# The digest type
  $digest_type              = 'sha256',
# Temporary directory to download the files to
  $tmp_dir                  = '/tmp',
# Marathon Installation directory
  $install_dir              = '/opt/marathon',
# The username that marathon will submit tasks as
  $user                     = 'root',
# Create symlinks for the marathon binaries for easier access
  $create_symlinks          = true,
# Whether to use haproxy for load balancing between services
  $haproxy_discovery        = false,
# Whether to use nginx for load balancing between services
  $nginx_discovery          = false,
# Nginx service configurations directory
  $nginx_services_dir       = '/etc/nginx/services.d',
# Create and manage the marathon service
  $manage_service           = true,
# The marathon service's name
  $service_name             = 'marathon',
# The marathon options
  $options                  = hiera('classes::marathon::options', { }),
# Manage the firewall rules
  $manage_firewall          = false,
# Manage the user that the tasks will be submitted as
  $manage_user              = true,
# Whether or not the integrity of the archive should be verified
  $checksum                 = true,
# Whether or not to use consul (http://consul.io) for service discovery
  $consul_discovery         = false,
# Consul configuration
  $consul_options           = hiera('classes::consul::options',{ }),
# Whether to install consul-template or not
  $install_consul_template  = false,
# Consul-template options
  $consul_template_options  = hiera('classes::consul_template::options', { }),
# Consul template watches
  $consul_template_watches  = hiera('classes::consul_template::watches', { }),
# Whether to install docker or not
  $install_docker           = true,
# Docker socket path
  $docker_socket_bind       = '/var/run/docker.sock',
# Docker DNS
  $docker_dns               = '8.8.8.8',
# Whether to install registraator or not
  $install_registrator      = true,
# How often should registrator query docker for services (See: https://github.com/gliderlabs/registrator)
  $registrator_resync       = 30,
# Additional registrator flags
  $registrator_args         = '',
# Setup consul DNS forwarding (see https://www.consul.io/docs/guides/forwarding.html for more details)
  $setup_dns_forwarding     = false,
# IPv4 Addresses for bind to listen on
  $bind_ipv4_listen_ips     = ['127.0.0.1'],
# IPv6 Addresses for bind to listen on
  $bind_ipv6_listen_ips     = ['::1'],
# Addresses for bind to allow recursion from (Can be both IPv6 and IPv4)
  $bind_recursion_ips       = ['127.0.0.1','::1']
) {

  validate_bool(
    $create_symlinks,
    $manage_service,
    $manage_firewall,
    $manage_user,
    $haproxy_discovery,
    $nginx_discovery,
    $consul_discovery,
    $checksum,
    $install_consul_template,
    $install_docker,
    $install_registrator,
    $setup_dns_forwarding
  )
  validate_absolute_path(
    $tmp_dir,
    $install_dir,
    $docker_socket_bind,
    $nginx_services_dir
  )
  validate_string(
    $url,
    $digest_string,
    $user,
    $docker_dns,
    $registrator_args
  )
  validate_integer($registrator_resync)
  validate_re($installation_ensure, '^(present|absent)$',"${installation_ensure} is not supported for installation_ensure. Allowed values are 'present' and 'absent'.")
  validate_hash(
    $options,
    $consul_options,
    $consul_template_options,
    $consul_template_watches
  )
  validate_array(
    $bind_ipv4_listen_ips,
    $bind_ipv6_listen_ips,
    $bind_recursion_ips
  )
  if $options != undef and $options['HTTP_ADDRESS'] != undef {
    if  !has_interface_with('ipaddress', $options['HTTP_ADDRESS']) {
      fail('The specified IP does not belong to this host.')
    }
  }

  anchor{ 'marathon::install::start': } ->
  class { 'marathon::install': } ->
  anchor { 'marathon::install::end': }

  if $consul_discovery == true {
    anchor{ 'marathon::haproxy_config::start': } ->
    class { 'marathon::haproxy_config': }
    anchor{ 'marathon::haproxy_config::end': }
  }

}
