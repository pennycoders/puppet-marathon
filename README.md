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
        # Whether or not to create scripts in /usr/local/bin
          $create_symlinks          = true,
        # Create symlinks for the marathon binaries for easier access
          $haproxy_discovery        = false,
        # Create and manage the marathon service
          $manage_service           = true,
        # The marathon service's name
          $service_name             = 'marathon',
        # The marathon options
          $options                  = hiera('classes::marathon::options', {}),
        # Manage the firewall rules
          $manage_firewall          = false,
        # Manage the user that the tasks will be submitted as
          $manage_user              = true,
        # Whether or not the integrity of the archive should be verified
          $checksum                 = true,
        # Global haproxy options
          $haproxy_global_options   = hiera('classes::haproxy::global_options', {}),
        # Default HAproxy options
          $haproxy_default_options  = hiera('classes::haproxy::default_options', {})
        ) {
    ```
    
* __marathon::install:__ This is the class that actually installs and configures marathon
    * __Parameters:__
    ```puppet
        class marathon::install (
        # Install or uninstall (present|absent)
          $installation_ensure     = 'present',
        # Marathon binary url
          $url                     = $marathon::url,
        # Marathon binary digest string
          $digest_string           = $marathon::digest_string,
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
    Please see [The Marathon documentation](https://mesosphere.github.io/marathon/docs/command-line-flags.html) before you use to use this module.
    
## Other notes

Pay attention when specifying the marathon options in Hiera, specially the ones requiring double quotes or special characters,
such as in the example below.
```json
    "ACCESS_CONTROL_ALLOW_ORIGIN":"\\\"*\\\"",
```

As you can see, since I am using the json Hiera backend, both the " and the \ need to be present within the service file.
Due to the fact that within the template they are already within double quotes, I had to make sure I escape them propperly.

Have fun!

#### __IMPORTANT:__

#### __TO DO:__

Add haproxy installation and configuration support
