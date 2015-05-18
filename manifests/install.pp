# Marathon installation class
class marathon::install (
      # Install or uninstall (present|absent)
        $installation_ensure      = $marathon::installation_ensure,
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
      # Create symlinks for the marathon binaries for easier access
        $create_symlinks          = $marathon::create_symlinks,
      #  Whether to use haproxy for load balancing between services
        $haproxy_discovery        = false,
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
      #  Whether or not to use consul (http://consul.io) for service discovery
        $consul_discovery         = $marathon::consul_discovery,
      #  Consul configuration
        $consul_options           = $marathon::consul_options,
      # Whether to install consul-template or not
        $install_consul_template  = $marathon::install_consul_template,
      #  consul-template options
        $consul_template_options  = $marathon::consul_template_options
) inherits marathon {

  validate_bool($create_symlinks, $manage_service, $manage_firewall, $manage_user, $haproxy_discovery, $consul_discovery, $checksum, $install_consul_template)
  validate_absolute_path($tmp_dir, $install_dir)
  validate_string($url, $digest_string, $user)
  validate_re($installation_ensure, '^(present|absent)$',"${installation_ensure} is not supported for installation_ensure. Allowed values are 'present' and 'absent'.")
  validate_hash($options, $consul_options, $consul_template_options)

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

  file { $install_dir:
    ensure  => directory,
    owner   => $user,
    mode    => 'u=rwxs,o=r',
    recurse => true
  }

  if $manage_service == true {
    file { "/usr/lib/systemd/system/${service_name}.service":
      ensure  => file,
      content => template('marathon/services/marathon.service.erb'),
      owner   => $user,
      mode    => 'u=rwxs,o=r',
      notify  => [Exec["Reload_for_${service_name}"]],
      require => [Archive[$service_name]]
    }

    service { $service_name:
      ensure   => 'running',
      provider => 'systemd',
      enable   => true,
      require  => [Exec["Reload_for_${service_name}"]]
    }

    exec{ "Reload_for_${service_name}":
      path    => [$::path],
      command => 'systemctl daemon-reload',
      notify  => [Service[$service_name]],
      require => [File["/usr/lib/systemd/system/${service_name}.service"]]
    }
  }
}