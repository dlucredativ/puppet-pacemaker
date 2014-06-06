# == Class: nfs-pacemaker
#
# See README.md
#
# === Authors
#
# - Vaidas Jablonskis <jablonskis@gmail.com>
#
class nfs-pacemaker (
  $service       = 'running',
  $onboot        = true,
  $package       = 'installed',
  $bindnetaddr   = params_lookup('bindnetaddr'),
  $mcastaddr     = params_lookup('mcastaddr'),
  $mcastport     = params_lookup('mcastport'),
  $service_delay = 0,
) {
  case $::osfamily {
    Debian: {
      # do nothing - supported distro
    }
    default: {
      fail("Module ${module_name} is not supported on ${::operatingsystem}")
    }
  }

  $package_name           = 'corosync'
  $pacemaker_package_name = 'pacemaker'
  $service_name           = 'corosync'

  $pcmk_service_file      = '/etc/corosync/service.d/pacemaker'
  $pcmk_service_template  = 'pacemaker.erb'

  $config_file            = '/etc/corosync/corosync.conf'
  $conf_template          = 'corosync.conf.erb'

  $default_file           = '/etc/default/corosync'
  $default_file_template  = 'corosync.default.erb'

  if $bindnetaddr == undef {
    fail('Please specify bindnetaddr.')
  }

  if $mcastaddr == undef {
    fail('Please specify mcastaddr.')
  }

  package { $package_name:
    ensure  => $package,
  }

  package { $pacemaker_package_name:
    ensure  => installed,
  }

  package { 'psmisc':
    ensure  => installed,
  }

  service { $service_name:
    ensure     => $service,
    enable     => $onboot,
    hasrestart => true,
    hasstatus  => true,
    require    => [
                    File[$config_file],
                    File[$default_file],
                    Package[$package_name]
                  ],
  }

  file { $config_file:
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template("${module_name}/${conf_template}"),
    notify  => Service[$service_name],
    require => Package[$package_name],
  }

  file { $pcmk_service_file:
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template("${module_name}/${pcmk_service_template}"),
    notify  => Service[$service_name],
    require => Package[$package_name],
  }

  if $::osfamily == 'Debian' {
    file { $default_file:
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template("${module_name}/${default_file_template}"),
      require => Package[$package_name],
    }
  }
}
