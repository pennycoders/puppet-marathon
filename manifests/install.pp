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
# Purge the installation directory
  $purge_install_dir        = $marathon::purge_install_dir,
# The username that marathon will submit tasks as
  $user                     = $marathon::user,
# Create symlinks for the marathon binaries for easier access
  $create_symlinks          = $marathon::create_symlinks,
# Whether to use haproxy for load balancing between services
  $haproxy_discovery        = $marathon::haproxy_discovery,
# Whether to use nginx for load balancing between services
  $nginx_discovery          = $marathon::nginx_discovery,
# Nginx service configurations directory
  $nginx_services_dir       = $marathon::nginx_services_dir,
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
# Whether or not to use consul (http://consul.io) for service discovery
  $consul_discovery         = $marathon::consul_discovery,
# Consul configuration
  $consul_options           = $marathon::consul_options,
# Whether to install consul-template or not
  $install_consul_template  = $marathon::install_consul_template,
# Consul-template options
  $consul_template_options  = $marathon::consul_template_options,
# Consul template watches
  $consul_template_watches  = $marathon::consul_template_watches,
# Whether to install docker or not
  $install_docker           = $marathon::install_docker,
# Docker options (for more details read https://github.com/garethr/garethr-docker)
  $docker_options           = $marathon::docker_options,
# Whether to install registraator or not
  $install_registrator      = $marathon::install_registrator,
# How often should registrator query docker for services (See: https://github.com/gliderlabs/registrator)
  $registrator_resync       = $marathon::registrator_resync,
# Additional registrator flags
  $registrator_args         = $marathon::registrator_args,
# Setup consul DNS forwarding (see https://www.consul.io/docs/guides/forwarding.html for more details)
  $setup_dns_forwarding     = $marathon::setup_dns_forwarding,
# IPv4 Addresses for bind to listen on
  $bind_ipv4_listen_ips     = $marathon::bind_ipv4_listen_ips,
# IPv6 Addresses for bind to listen on
  $bind_ipv6_listen_ips     = $marathon::bind_ipv6_listen_ips,
# Addresses for bind to allow recursion from (Can be both IPv6 and IPv4)
  $bind_recursion_ips       = $marathon::bind_recursion_ips
) inherits marathon {

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
    $setup_dns_forwarding,
    $purge_install_dir
  )
  validate_absolute_path(
    $tmp_dir,
    $install_dir,
    $nginx_services_dir
  )
  validate_string(
    $url,
    $digest_string,
    $user,
    $registrator_args
  )
  validate_integer($registrator_resync)
  validate_re($installation_ensure, '^(present|absent)$',"${installation_ensure} is not supported for installation_ensure. Allowed values are 'present' and 'absent'.")
  validate_hash(
    $options,
    $consul_options,
    $consul_template_options,
    $consul_template_watches,
    $docker_options
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

  if $manage_user == true and !defined(User[$user]) and !defined(Group[$user]) and $user != 'root' {
    ensure_resource('group', $user, {
      ensure => present,
      name   => $user
    })

    ensure_resource('user', $user, {
      ensure     => present,
      managehome => true,
      shell      => '/sbin/nologin',
      require    => [Group[$user]],
      groups     => [$user,'root']
    })

  } elsif  $manage_user == true and !defined(User[$user]) and $user == 'root' {

    ensure_resource('user', $user, {
      ensure     => present
    })

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
    digest_string    => $digest_string,
    digest_type      => $digest_type,
    purge_target     => $purge_install_dir,
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