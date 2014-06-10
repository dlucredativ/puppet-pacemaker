# == Class: pacemaker
#
# See README.md
#
class pacemaker (
  $package       = 'installed',
  $bindnetaddr   = params_lookup('bindnetaddr'),
  $mcastaddr     = params_lookup('mcastaddr'),
  $mcastport     = params_lookup('mcastport'),
  $sbd_active    = params_lookup('sbd_active'),
  $sbd_device    = params_lookup('sbd_device'),
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

  $sbd_watchdog           = 'pacemaker-sbd'
  $sbd_watchdog_pkg       = 'pacemaker-sbd-watchdog'

  if $bindnetaddr == undef {
    fail('Please specify bindnetaddr.')
  }

  if $mcastaddr == undef {
    fail('Please specify mcastaddr.')
  }

  if $mcastport == undef {
    fail('Please specify mcastport.')
  }

  if $sbd_device == undef {
    fail('Please specify sbd_device.')
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

  package { $sbd_watchdog_pkg:
    ensure  => installed,
    require  => Exec['apt-get update'],
  }

  exec { 'apt-get update' :
    command => '/usr/bin/apt-get update',
    require  => Class['apt_sources'],
  }

  service { $sbd_watchdog:
    enable     => $sbd_active,
    ensure     => $sbd_active,
    hasrestart => true,
    hasstatus  => true,
    require    => [
                    File["/etc/default/${sbd_watchdog}"],
                    Package[$sbd_watchdog_pkg],
                  ],
  }

  service { $service_name:
    enable     => false,
    hasrestart => true,
    hasstatus  => true,
    require    => [
                    File[$config_file],
                    File[$default_file],
                    Package[$package_name],
                  ],
  }

  file { "/etc/default/${sbd_watchdog}":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template("${module_name}/${sbd_watchdog}.default.erb"),
    require => Package[$sbd_watchdog_pkg],
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
