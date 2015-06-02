class marathon::haproxy_config (
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

  if $install_docker == true {
    ensure_resource('class', 'docker', $docker_options)
  }

  if $haproxy_discovery == true  and $nginx_discovery == false {
    ensure_resource('package','haproxy',{
      ensure => 'latest'
    })
  }

  if $nginx_discovery == true  and $haproxy_discovery == false {
    ensure_resource('yumrepo','nginx', {
      descr    => 'Nginx repository',
      baseurl  => 'http://nginx.org/packages/mainline/centos/$releasever/$basearch/',
      gpgcheck => 0,
      enabled  => 1
    })

    ensure_resource('package','nginx',{
      ensure  => 'latest',
      require => [Yumrepo['nginx']]
    })

    ensure_resource('file',$nginx_services_dir, {
      ensure  => 'directory',
      owner   => $user,
      purge   => true,
      recurse => true,
      require => [Package['nginx']],
      mode    => 'ug=rwxs,o=srwx'
    })

    ensure_resource('file_line','include services configuration files',{
      ensure  => 'present',
      path    => '/etc/nginx/nginx.conf',
      line    => "include ${nginx_services_dir}/*.conf;",
      require => [
        File[$nginx_services_dir]
      ]
    })

  }

  if $consul_discovery == true {

    ensure_resource('class', 'consul', $consul_options)

    if is_hash($consul_options['config_hash']) {
      if $consul_options['config_hash']['client_addr'] != undef {
        $consulHTTPAddress = $consul_options['config_hash']['client_addr']
      }

      if $consul_options['config_hash']['ports'] and
      $consul_options['config_hash']['ports']['http'] != undef {
        $consulHTTPPort = $consul_options['config_hash']['ports']['http']
      } else {
        $consulHTTPPort = 8500
      }

      ensure_resource('consul::service','consul-http',{
        checks  => [
          {
            id       => 'consul-http-check',
            interval => '10s',
            http     => "http://${consulHTTPAddress}:${consulHTTPPort}/v1/catalog/services",
            name     => "Consul web-ui is running on $consulHTTPPort"
          }
        ],
        port    => $consulHTTPPort
      })
    }

    if $setup_dns_forwarding == true {

      if $bindV4ipsString == undef {
        $bindV4ipsString = join($bind_ipv4_listen_ips,'; ')
      }

      if $bindV6ipsString == undef {
        $bindV6ipsString = join($bind_ipv6_listen_ips,'; ')
      }

      if $bindRecursionIPsString == undef {
        $bindRecursionIPsString = join($bind_recursion_ips,'; ')
      }

      if $ipv4ListenLine == undef and $bindV4ipsString != undef {
        $ipv4ListenLine = "listen-on port 53 { ${bindV4ipsString}; };"
      }

      if $ipv6ListenLine == undef and $bindV6ipsString != undef {
        $ipv6ListenLine = "listen-on-v6 port 53 { ${bindV6ipsString}; };"
      }

      if $recursionIPsLine == undef and $bindRecursionIPsString != undef {
        $recursionIPsLine = "allow-recursion { ${bindRecursionIPsString}; };"
      }

      if is_hash($consul_options['config_hash']) and
      $consul_options['config_hash']['domain'] {
        $consul_dns_domain = $consul_options['config_hash']['domain']
      }

      if is_hash($consul_options['config_hash']) and
      is_hash($consul_options['config_hash']['ports']) and
      $consul_options['config_hash']['ports']['dns'] {
        $consul_dns_port = $consul_options['config_hash']['ports']['dns']
      }

      if is_hash($consul_options['config_hash']) and
      $consul_options['config_hash']['client_addr'] {
        $consul_dns_address = $consul_options['config_hash']['client_addr']
      }

      ensure_resource('package', 'bind', {
        ensure => 'latest'
      })

      ensure_resource('file', '/etc/named/consul.zone.conf',{
        ensure  => 'file',
        purge   => true,
        require => [
          Package['bind'],
          Class['consul']
        ],
        content => template('marathon/configurations/consul_dns.conf.erb'),
        owner   => $user,
        mode    => 'u=rwxs,o=r'
      })

      ensure_resource('file_line','nameserver 127.0.0.1',{
        ensure  => 'present',
        path    => '/etc/resolv.conf',
        line    => 'nameserver 127.0.0.1',
        require => [
          File['/etc/named/consul.zone.conf']
        ]
      })

      ensure_resource('file_line','recursion yes;',{
        ensure  => 'present',
        path    => '/etc/named.conf',
        line    => 'recursion yes;',
        match   => '^.*?recursion.*\s(yes|no);$',
        require => [File_line['nameserver 127.0.0.1']],
        notify  => [Service['named']]
      })

      ensure_resource('file_line','set bind ipv4 addresses',{
        ensure  => 'present',
        path    => '/etc/named.conf',
        line    => $ipv4ListenLine,
        after   => 'recursion yes;',
        match => '^.*?listen-on\sport\s53.*;$',
        require => [File_line['nameserver 127.0.0.1']],
        notify  => [Service['named']]
      })

      ensure_resource('file_line','set bind ipv6 addresses',{
        ensure  => 'present',
        path    => '/etc/named.conf',
        line    => $ipv6ListenLine,
        after   => $ipv4ListenLine,
        match   => '^.*?listen-on-v6\sport\s53.*;$',
        require => [File_line['set bind ipv4 addresses']],
        notify  => [Service['named']]
      })

      ensure_resource('file_line','set bind recursion ips',{
        ensure  => 'present',
        path    => '/etc/named.conf',
        line    => $recursionIPsLine,
        after   => $ipv6ListenLine,
        match   => '^.*?allow-recursion.*;$',
        require => [File_line['set bind ipv6 addresses']],
        notify  => [Service['named']]
      })

      ensure_resource('file_line','dnssec-enable no;',{
        ensure  => 'present',
        path    => '/etc/named.conf',
        line    => 'dnssec-enable no;',
        match   => '^.*?dnssec-enable.*;$',
        require => [File_line['set bind recursion ips']],
        notify  => [Service['named']]
      })

      ensure_resource('file_line','dnssec-validation no;',{
        ensure  => 'present',
        path    => '/etc/named.conf',
        line    => 'dnssec-validation no;',
        match   => '.*?dnssec-validation.*;$',
        require => [File_line['dnssec-enable no;']],
        notify  => [Service['named']]
      })

      ensure_resource('file_line','include_/etc/named/*.conf',{
        ensure  => 'present',
        path    => '/etc/named.conf',
        line    => 'include "/etc/named/consul.zone.conf";',
        require => [
          File_line['nameserver 127.0.0.1'],
          File_line['dnssec-validation no;']
        ],
        notify  => [Service['named']]
      })

      ensure_resource('service','named',{
        ensure  => 'running'
      })
    }
  }

  $registratorInterestedParties = defined(Service['consul']) ? {
    true  => Service['consul'],
    false => undef
  }
  if $install_registrator == true and $consul_discovery == true and $install_consul_template == true and is_hash($consul_options['config_hash']) and $consul_options['config_hash']['client_addr'] {
    /*ensure_resource('docker::run','registrator', {
      image           => 'gliderlabs/registrator:latest',
      notify          => $registratorInterestedParties,
      command         => "-ip ${consul_options['config_hash']['client_addr']} consul://${consul_options['config_hash']['client_addr']}:${consul_template_options['consul_port']} -resync ${registrator_resync} ${registrator_args}",
      use_name        => true,
      volumes         => ["${docker_socket_bind}:/tmp/docker.sock"],
      memory_limit    => '10m',
      hostname        => $::fqdn,
      pull_on_start   => true
  })*/
}


if $install_consul_template == true {
  ensure_resource('class', 'consul_template', $consul_template_options)
}

if is_hash($consul_template_watches) and count($consul_template_watches) > 0 {
  create_resources('consul_template::watch', $consul_template_watches)
}
}