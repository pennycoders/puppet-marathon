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
  $consul_template_options  = $marathon::consul_template_options,
# Whether to install docker or not
  $install_docker           = $marathon::install_docker,
# Docker socket path
  $docker_socket_bind       = $marathon::docker_socket_bind,
# Docker DNS
  $docker_dns               = $marathon::docker_dns,
# Whether to install registraator or not
  $install_registrator      = $marathon::install_registrator
) inherits marathon {

  validate_bool(
    $create_symlinks,
    $manage_service,
    $manage_firewall,
    $manage_user,
    $haproxy_discovery,
    $consul_discovery,
    $checksum,
    $install_consul_template,
    $install_docker,
    $install_registrator
  )
  validate_absolute_path(
    $tmp_dir,
    $install_dir,
    $docker_socket_bind
  )
  validate_string(
    $url,
    $digest_string,
    $user,
    $docker_dns
  )
  validate_re($installation_ensure, '^(present|absent)$',"${installation_ensure} is not supported for installation_ensure. Allowed values are 'present' and 'absent'.")
  validate_hash(
    $options,
    $consul_options,
    $consul_template_options
  )

  if $options != undef and $options['HTTP_ADDRESS'] != undef {
    if  !has_interface_with('ipaddress', $options['HTTP_ADDRESS']) {
      fail('The specified IP does not belong to this host.')
    }
  }

  if $install_docker == true {
    ensure_resource('class','docker',{
      dns          => $docker_dns,
      socket_bind  => "unix:///${docker_socket_bind}",
      docker_users => [$user],
      socket_group => $user
    })
  }

  if $haproxy_discovery == true {
    ensure_resource('package','haproxy',{
      ensure => 'latest'
    })
  }

  if $consul_discovery == true {
    ensure_resource('class', 'consul', $consul_options)
  }

  if $install_registrator == true {
  #    docker run -d -v /run/docker.sock:/tmp/docker.sock -h $HOSTNAME gliderlabs/registrator -ip 172.16.0.98 consul://172.0.16.98:8500 -join=172.16.0.98
    ensure_resource('docker::run','registrator', {
      image           => 'gliderlabs/registrator:latest',
      command         => "-ip ${consul_options['client_addr']} consul://${consul_template_options['consul_host']}:${consul_template_options['consul_port']}",
      use_name        => true,
      volumes         => ["${docker_socket_bind}:/tmp/docker.sock"],
      memory_limit    => '10m',
      hostname        => "${::fqdn}",
      pull_on_start   => true
    })
  }


  if $install_consul_template == true {
    ensure_resource('class', 'consul_template', $consul_template_options)
  }
}