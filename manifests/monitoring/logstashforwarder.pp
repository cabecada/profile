# logstashforwarder
class profile::monitoring::logstashforwarder {

  $logstashserver = hiera('profile::monitoring::logstashserver')

  class { '::logstashforwarder':
    servers     => [ "${logstashserver}" ],
#    ssl_key     => 'puppet:///modules/profile/keys/private/logstash-forwarder.key',
    ssl_ca      => 'puppet:///modules/profile/keys/certs/selfsigned.crt',
#    ssl_cert    => 'puppet:///modules/profile/keys/certs/logstash-forwarder.crt',
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



}
