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
      $url                      = 'https://downloads.mesosphere.io/marathon/v0.8.2-RC4/marathon-0.8.2-RC4.tgz',
    # Marathon binary digest string
      $digest_string            = '7159bd327a6b7ad7dd7e92bb490fc1cc229bc5f799f34a91da7b9e60a42454c3',
    # The digest type
      $digest_type              = 'sha256',
    # Temporary directory to download the files to
      $tmp_dir                  = '/tmp',
    # Marathon Installation directory
      $install_dir              = '/opt/marathon',
    # Purge the installation directory
      $purge_install_dir        = false,
    # The username that marathon will submit tasks as
      $user                     = 'root',
    # Create symlinks for the marathon binaries for easier access
      $create_symlinks          = true,
    # Whether to use haproxy for load balancing between services
      $haproxy_discovery        = false,
    # Whether to use nginx for load balancing between services
      $nginx_discovery          = false,
    # Nginx service configurations directory
      $nginx_services_dir       = '/etc/nginx/services.d',
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
    # Docker options (for more details read https://github.com/garethr/garethr-docker)
      $docker_options           = hiera('classes::docker::options', {
        dns          => '8.8.8.8',
        socket_bind  => "unix:///var/run/docker.sock",
        docker_users => [$user],
        socket_group => $user
      }),
    # Whether to install registraator or not
      $install_registrator      = true,
    # How often should registrator query docker for services (See: https://github.com/gliderlabs/registrator)
      $registrator_resync       = 30,
    # Additional registrator flags
      $registrator_args         = '',
    # Setup consul DNS forwarding (see https://www.consul.io/docs/guides/forwarding.html for more details)
      $setup_dns_forwarding     = false,
    # IPv4 Addresses for bind to listen on
      $bind_ipv4_listen_ips     = ['127.0.0.1'],
    # IPv6 Addresses for bind to listen on
      $bind_ipv6_listen_ips     = ['::1'],
    # Addresses for bind to allow recursion from (Can be both IPv6 and IPv4)
      $bind_recursion_ips       = ['127.0.0.1','::1']
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

## NEW FEATURES:
* Flexible load balancing configuration (Now you can also opt for nginx, as your load balancer __(ver. 1.0.12 and above)__
* You can now configure dns forwarding, by using consul's dns 
  interface (see https://www.consul.io/docs/agent/dns.html and https://www.consul.io/docs/guides/forwarding.html for more details)
  __(ver. 1.0.12 and above)__.
* You can also set as many template watchers as you want, for any (custom) load balancer, 
  or anything that supports a file-based configuration. __(ver. 1.0.12 and above)__.