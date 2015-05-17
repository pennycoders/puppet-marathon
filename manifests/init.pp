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
  $url                      = 'https://downloads.mesosphere.io/marathon/v0.8.2-RC1/marathon-0.8.2-RC1.tgz',
# Marathon binary digest string
  $digest_string            = '45a481f4703e1455f8aafa037705c9033200f2dc7f9d5e6414acde533d6cb935',
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
#  Whether to use haproxy for load balancing between services
  $haproxy_discovery        = false,
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
#  Whether or not to use consul (http://consul.io) for service discovery
  $consul_discovery         = false,
#  Consul package url
  $consul_url               = 'https://dl.bintray.com/mitchellh/consul/0.5.0_linux_amd64.zip',
#  Whether the consul package's integrity should be verified
  $consul_checksum          = true,
#  Consul digest string
  $consul_digest_string     = '161f2a8803e31550bd92a00e95a3a517aa949714c19d3124c46e56cfdc97b088',
#  Consul configuration
  $consul_options           = hiera('classes::consul::options',{ })
) {

  validate_bool($create_symlinks, $manage_service, $manage_firewall, $manage_user, $haproxy_discovery, $consul_discovery, $checksum, $consul_checksum)
  validate_absolute_path($tmp_dir, $install_dir)
  validate_string($url, $digest_string, $user, $consul_digest_string, $consul_url)
  validate_re($installation_ensure, '^(present|absent)$',"${installation_ensure} is not supported for installation_ensure. Allowed values are 'present' and 'absent'.")
  validate_hash($options, $consul_options)

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
