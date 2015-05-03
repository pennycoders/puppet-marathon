# Marathon installation class

class marathon::install (
# Install or uninstall (present|absent)
  $installation_ensure     = 'present',
# Marathon binary url
  $url                     = $marathon::url,
# Marathon binary digest url
  $digest_string              = $marathon::digest_string,
# The digest type
  $digest_type             = 'sha256',
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
  $service_name            = $marathon::service_name,
# The marathon options
  $options                 = $marathon::options,
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

  validate_bool($create_symlinks, $manage_service, $manage_firewall, $manage_user, $haproxy_discovery, $checksum)
  validate_absolute_path($tmp_dir, $install_dir)
  validate_string($url, $digest_string, $user)
  validate_re($installation_ensure, '^(present|absent)$',"${installation_ensure} is not supported for installation_ensure. Allowed values are 'present' and 'absent'.")
  validate_hash($options, $haproxy_global_options, $haproxy_default_options)

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

  ensure_resource('archive', $service_name, {
    ensure           => present,
    url              => $url,
    src_target       => $tmp_dir,
    target           => $install_dir,
    strip_components => 1,
    follow_redirects => true,
    extension        => 'tgz',
    checksum         => $checksum,
    digest_string       => $digest_string,
    digest_type      => $digest_type,
    notify           => [File[$install_dir]]
  })

  if $manage_firewall == true and $options['HTTP_ADDRESS'] != undef and $options['HTTP_PORT'] != undef {
    if !defined(Class['firewalld2iptables']) {
      class { 'firewalld2iptables':
        manage_package   => true,
        iptables_ensure  => 'latest',
        iptables_enable  => true,
        ip6tables_enable => true
      }
    }

    if !defined(Class['firewall']) {
      class { 'firewall': }
    }

    if !defined(Service['firewalld']) {
      service { 'firewalld':
        ensure => 'stopped'
      }
    }

    firewall { "0_${service_name}_allow_incoming":
      port        => [$options['HTTP_PORT']],
      proto       => 'tcp',
      require     => [Class['firewall']],
      destination => $options['HTTP_ADDRESS'],
      action      => 'accept'
    }
  }

  file {$install_dir:
    ensure  => directory,
    content => template('marathon/services/marathon.service.erb'),
    owner   => $user,
    mode    => 'u=rwxs,o=r',
    recurse => true
  }

  if $manage_service == true {
    file {"/usr/lib/systemd/system/${service_name}.service":
      ensure  => file,
      content => template('marathon/services/marathon.service.erb'),
      owner   => $user,
      mode    => 'u=rwxs,o=r',
      recurse => true,
      require => [Archive[$service_name]]
    }

    service {"${service_name}":
      ensure   => 'running',
      provider => 'systemd',
      enable   => true,
      require  => [Exec["Reload_for_${service_name}"]]
    }

    exec{ "Reload_for_${service_name}":
      path        => [$::path],
      command     => 'systemctl daemon-reload',
      refreshonly => true,
      notify      => [Service[$service_name]],
      require     => [File["/usr/lib/systemd/system/${service_name}.service"]]
    }
  }
}