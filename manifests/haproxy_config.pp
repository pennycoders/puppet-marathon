class marathon::haproxy_config (
  # Install or uninstall (present|absent)
    $installation_ensure     = $marathon::installation_ensure,
  # Marathon binary url
    $url                      = $marathon::url,
  # Marathon binary digest string
    $digest_string            = $marathon::digest_string,
  # The digest type
    $digest_type              = $marathon::digest_type,
  # Temporary directory to download the files to
    $tmp_dir                  = $marathon::tmp_dir,
  # Marathon Installation directory
    $install_dir              = $marathon::install_dir,
  # The username that marathon will submit tasks as
    $user                     = $marathon::user,
  # Whether or not to create scripts in /usr/local/bin
    $create_symlinks          = $marathon::create_symlinks,
  # Create symlinks for the marathon binaries for easier access
    $haproxy_discovery        = $marathon::haproxy_discovery,
  # Create and manage the marathon service
    $manage_service           = $marathon::manage_service,
  # The marathon service's name
    $service_name             = $marathon::service_name,
  # The marathon options
    $options                  = $marathon::options,
  # Manage the firewall rules
    $manage_firewall          = $marathon::manage_firewall,
  # Manage the user that the tasks will be submitted as
    $manage_user              = $marathon::manage_user,
  # Whether or not the integrity of the archive should be verified
    $checksum                 = $marathon::checksum,
  # Global haproxy options
    $haproxy_global_options   = $marathon::haproxy_global_options,
  # Default HAproxy options
    $haproxy_defaults_options = $marathon::haproxy_defaults_options
) inherits marathon {

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

  ensure_resource('class', 'haproxy',{
    haproxy_global_options  => $haproxy_global_options,
    haproxy_defaults_options => $haproxy_defaults_options
  })
}