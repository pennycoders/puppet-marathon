# Puppet module for mesosphere's Marathon #

This module installs and configures Mesosphere's marathon task runner.


## Classes:

* __marathon:__ This is the main class, all the other sub-classes inherit from it.
    * __Parameters:__ 
```puppet
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
    # Whether to use haproxy for load balancing between services
      $haproxy_discovery        = false,
    # Whether to use nginx for load balancing between services
      $nginx_discovery          = false,
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
    # Whether or not to use consul (http://consul.io) for service discovery
      $consul_discovery         = false,
    # Consul configuration
      $consul_options           = hiera('classes::consul::options',{ }),
    # Whether to install consul-template or not
      $install_consul_template  = false,
    # Consul-template options
      $consul_template_options  = hiera('classes::consul_template::options', { }),
    # Consul template watches
      $consul_template_watches  = hiera('classes::consul_template::watches', { }),
    # Whether to install docker or not
      $install_docker           = true,
    # Docker socket path
      $docker_socket_bind       = '/var/run/docker.sock',
    # Docker DNS
      $docker_dns               = '8.8.8.8',
    # Whether to install registraator or not
      $install_registrator      = true,
    # How often should registrator query docker for services (See: https://github.com/gliderlabs/registrator)
      $registrator_resync       = 30,
    # Additional registrator flags
      $registrator_args         = ''
) {
```
    
* __marathon::install:__ This is the class that actually installs and configures marathon
    * __Parameters:__
```puppet
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
    # Whether to use haproxy for load balancing between services
      $haproxy_discovery        = $marathon::haproxy_discovery,
    # Whether to use nginx for load balancing between services
      $nginx_discovery          = $marathon::nginx_discovery,
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
      $consul_template_watches  = hiera('classes::consul_template::watches', { }),
    # Whether to install docker or not
      $install_docker           = $marathon::install_docker,
    # Docker socket path
      $docker_socket_bind       = $marathon::docker_socket_bind,
    # Docker DNS
      $docker_dns               = $marathon::docker_dns,
    # Whether to install registraator or not
      $install_registrator      = $marathon::install_registrator,
    # How often should registrator query docker for services (See: https://github.com/gliderlabs/registrator)
      $registrator_resync       = $marathon::registrator_resync,
    # Additional registrator flags
      $registrator_args         = $marathon::registrator_args
) inherits marathon {
```

* __marathon::haproxy_config:__ This is the class that actually installs and configures haproxy
    * __Parameters:__
```puppet
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
    # Whether to use haproxy for load balancing between services
      $haproxy_discovery        = $marathon::haproxy_discovery,
    # Whether to use nginx for load balancing between services
      $nginx_discovery          = $marathon::nginx_discovery,
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
      $consul_template_watches  = hiera('classes::consul_template::watches', { }),
    # Whether to install docker or not
      $install_docker           = $marathon::install_docker,
    # Docker socket path
      $docker_socket_bind       = $marathon::docker_socket_bind,
    # Docker DNS
      $docker_dns               = $marathon::docker_dns,
    # Whether to install registraator or not
      $install_registrator      = $marathon::install_registrator,
    # How often should registrator query docker for services (See: https://github.com/gliderlabs/registrator)
      $registrator_resync       = $marathon::registrator_resync,
    # Additional registrator flags
      $registrator_args         = $marathon::registrator_args
) inherits marathon {
```
    
## Usage example:
```puppet
class {'marathon':
    manage_firewall => true,
    service_name    => 'marathon',
    manage_user     => true,
    user            => 'root'
}
```
## Important:
Before using this module, please see:
 * [The Marathon documentation](https://mesosphere.github.io/marathon/docs/command-line-flags.html)
 * [The consul documentation] (https://www.consul.io/docs/agent/options.html) and the [Consul puppet module documentation] (https://github.com/solarkennedy/puppet-consul)
 * [The Registrator documentation] (https://github.com/gliderlabs/registrator) and the [Docker puppet module documentation] (https://github.com/garethr/garethr-docker)
 * [The consul-template documentation] (https://github.com/hashicorp/consul-template) and the [consul_tempalte puppet module documentation] (https://github.com/gdhbashton/puppet-consul_template)

## Other notes

Pay attention when specifying the marathon options in Hiera, specially the ones requiring double quotes or special characters,
such as in the example below.
```json
    "ACCESS_CONTROL_ALLOW_ORIGIN":"\\\"*\\\"",
```

As you can see, since I am using the json Hiera backend, both the " and the \ need to be present within the service file.
Due to the fact that within the template they are already within double quotes, I had to make sure I escape them propperly.

Have fun!