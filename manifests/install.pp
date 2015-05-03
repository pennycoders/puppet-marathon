# Marathon installation class

class marathon::install (
# Install or uninstall (present|absent)
  $installation_ensure     = 'present',
# Marathon binary url
  $url                     = $marathon::url,
# Marathon binary digest url
  $digest_url            = $marathon::digest_url,
# The digest type
  $digest_type            = 'sha256',
# Temporary directory to download the files to
  $tmp_dir                 = $marathon::tmp_dir,
# Marathon Installation directory
  $install_dir             = $marathon::install_dir,
# The username that marathon will submit tasks as
  $user                    = $marathon::user,
# Whether or not to create scripts in /usr/local/bin
  $create_symlinks         = $marathon::create_symlinks,
# Create symlinks for the marathon binaries for easier access
  $haproxy_discovery       = $marathon::haproxy_discovery,
# Create and manage the marathon service
  $manage_service          = $marathon::manage_service,
# The marathon service's name
  $service_name             = $marathon::service_name,
# The marathon options
  $options                  = $marathon::options,
# Manage the firewall rules
  $manage_firewall         = $marathon::manage_firewall,
# Manage the user that the tasks will be submitted as
  $manage_user             = $marathon::manage_user,
# Whether or not the integrity of the archive should be verified
  $checksum                = $marathon::checksum,
# Global haproxy options
  $haproxy_global_options  = $marathon::haproxy_global_options,
# Default HAproxy options
  $haproxy_default_options = $marathon::haproxy_default_options
) inherits marathon {

  validate_bool($create_symlinks, $manage_service, $manage_firewall, $manage_user, $haproxy_discovery)
  validate_path($tmp_dir, $install_dir)
  validate_string($url, $digest_url, $user)
  validate_re($installation_ensure, '^(present|absent)$',"${installation_ensure} is not supported for installation_ensure. Allowed values are 'present' and 'absent'.")

  if $options != undef and $options['HTTP_ADDRESS'] != undef {
    if  !has_interface_with('ipaddress', $options['HTTP_ADDRESS']) {
      fail('The specified IP does not belong to this host.')
    }
  }

  if $manage_user == true and !defined(User[$user]) and !defined(Group[$user]) and $user != 'root' {
    group { $user:
      ensure => present,
      name   => $user
    }
    user { $user:
      ensure     => present,
      managehome => true,
      shell      => '/sbin/nologin',
      require    => [Group[$user]],
      groups     => [$user,'root']
    }
  } elsif  $manage_user == true and !defined(User[$user]) and $user == 'root' {
    user { $user:
      ensure     => present
    }
  }

  ensure_resource('archive', 'marathon', {
    ensure           => present,
    url              => $url,
    src_target       => $tmp_dir,
    target           => $install_dir,
    strip_components => 1,
    follow_redirects => true,
    extension        => 'tgz',
    checksum         => true,
    digest_url       => $digest_url,
    digest_type      => $digest_type
  })


}