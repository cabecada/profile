# This class starts to configure sudo
class profile::baseconfig::sudo {
  class { '::sudo': }

  sudo::conf { 'insults':
    priority => 10,
    content  => 'Defaults	insults',
  }

  sudo::conf { 'sensu-client':
    priority => 15,
    source   => 'puppet:///modules/profile/sudo/sensu_sudoers',
  }
}
