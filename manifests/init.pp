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
# Whether or not to create scripts in /usr/local/bin
  $create_symlinks          = true,
# Create symlinks for the marathon binaries for easier access
  $haproxy_discovery        = false,
# Create and manage the marathon service
  $manage_service           = true,
# The marathon service's name
  $service_name             = 'marathon',
# The marathon options
  $options                  = hiera('classes::marathon::options', {}),
# Manage the firewall rules
  $manage_firewall          = false,
# Manage the user that the tasks will be submitted as
  $manage_user              = true,
# Whether or not the integrity of the archive should be verified
  $checksum                 = true,
# Global haproxy options
  $haproxy_global_options   = hiera('classes::haproxy::global_options', {}),
# Default HAproxy options
  $haproxy_defaults_options = hiera('classes::haproxy::defaults_options', {})
) {

  validate_bool($create_symlinks, $manage_service, $manage_firewall, $manage_user, $haproxy_discovery, $checksum)
  validate_absolute_path($tmp_dir, $install_dir)
  validate_string($url, $digest_string, $user)
  validate_re($installation_ensure, '^(present|absent)$',"${installation_ensure} is not supported for installation_ensure. Allowed values are 'present' and 'absent'.")
  validate_hash($options, $haproxy_global_options, $haproxy_defaults_options)

  if $options != undef and $options['HTTP_ADDRESS'] != undef {
    if  !has_interface_with('ipaddress', $options['HTTP_ADDRESS']) {
      fail('The specified IP does not belong to this host.')
    }
  }

  anchor{ 'marathon::install::start': } ->
  class { 'marathon::install': } ->
  anchor { 'marathon::install::end': }

  if $haproxy_discovery == true {
    anchor{ 'marathon::haproxy_config::start': } ->
    class {'marathon::haproxy_config':}
    anchor{ 'marathon::haproxy_config::end': }
  }

}
