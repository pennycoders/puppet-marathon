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
  # Marathon binary digest url
  $digest_url             = 'https://downloads.mesosphere.io/marathon/v0.8.2-RC1/marathon-0.8.2-RC1.tgz.sha256',
  # The digest type
  $digest_type            = 'sha256',
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
  # Manage the firewall rules
  $manage_firewall          = false,
  # Manage the user that the tasks will be submitted as
  $manage_user              = true,
  # Whether or not the integrity of the archive should be verified
  $checksum                 = true,
  # Global haproxy options
  $haproxy_default_options  = hiera('haproxy::global_options', false),
  # Default HAproxy options
  $haproxy_default_options  = hiera('haproxy::default_options', false)
) {

  validate_bool($create_symlinks, $manage_service, $manage_firewall, $manage_user, $haproxy_discovery, $checksum)
  validate_path($tmp_dir, $install_dir)
  validate_string($url, $digest_url, $user)
  validate_re($installation_ensure, '^(present|absent)$',"${installation_ensure} is not supported for installation_ensure. Allowed values are 'present' and 'absent'.")

}
