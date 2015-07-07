# logstashforwarder
class profile::monitoring::logstashforwarder {

  $logstash_server = hiera('profile::monitoring::logstash_server')

  class { '::logstashforwarder':
    servers     => [ "${logstash_server}" ],
    ssl_ca      => 'puppet:///modules/profile/keys/certs/logstash.crt',
    manage_repo => true,
    autoupgrade => true,
  }
  logstashforwarder::file { 'syslog':
    paths  => [ '/var/log/syslog', '/var/log/auth.log' ],
    fields => { 'type' => 'syslog' },
  }
  logstashforwarder::file { 'nova':
    paths  => [ '/var/log/nova/*.log' ],
    fields => { 'type' => 'openstack', 'component' => 'nova' },
  }
  logstashforwarder::file { 'neutron':
    paths  => [ '/var/log/neutron/*.log' ],
    fields => { 'type' => 'openstack', 'component' => 'neutron' },
  }
  logstashforwarder::file { 'cinder':
    paths  => [ '/var/log/cinder/*.log' ],
    fields => { 'type' => 'openstack', 'component' => 'cinder' },
  }
  logstashforwarder::file { 'heat':
    paths  => [ '/var/log/heat/*.log' ],
    fields => { 'type' => 'openstack', 'component' => 'heat' },
  }
  logstashforwarder::file { 'keystone':
    paths  => [ '/var/log/keystone/*.log' ],
    fields => { 'type' => 'openstack', 'component' => 'keystone' },
  }
  logstashforwarder::file { 'glance':
    paths  => [ '/var/log/glance/*.log' ],
    fields => { 'type' => 'openstack', 'component' => 'glance' },
  }
  logstashforwarder::file { 'ceilometer':
    paths  => [ '/var/log/ceilometer/*.log' ],
    fields => { 'type' => 'openstack', 'component' => 'ceilometer' },
  }
  logstashforwarder::file { 'libvirt':
    paths  => [ '/var/log/libvirt/*.log' ],
    fields => { 'type' => 'libvirt' },
  }
  logstashforwarder::file { 'ceph':
    paths  => [ '/var/log/ceph/*.log' ],
    fields => { 'type' => 'ceph' },
  }

}
