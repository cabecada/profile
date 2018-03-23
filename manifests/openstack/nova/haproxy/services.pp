# Configures the haproxy frontend for the public nova API
class profile::openstack::nova::haproxy::services {
  require ::profile::services::haproxy
  require ::profile::services::haproxy::certs::serviceapi

  include ::profile::openstack::nova::firewall::haproxy
  include ::profile::openstack::nova::haproxy::backend::oldpublic

  $ipv4 = hiera('profile::haproxy::services::ipv4')
  $ipv6 = hiera('profile::haproxy::services::ipv6', false)
  $certificate = hiera('profile::haproxy::services::apicert', false)
  $certfile = hiera('profile::haproxy::services::apicert::certfile',
                    '/etc/ssl/private/haproxy.servicesapi.pem')

  $ft_options = {
    'default_backend' => 'bk_nova_public',
  }

  if($certificate) {
    $ssl = ['ssl', 'crt', $certfile]
  } else {
    $ssl = []
  }

  if($ipv6) {
    $bind = {
      "${ipv4}:8774" => $ssl,
      "${ipv6}:8774" => $ssl,
    }
  } else {
    $bind = {
      "${ipv4}:8774" => $ssl,
    }
  }

  haproxy::frontend { 'ft_nova_public':
    bind    => $bind,
    mode    => 'http',
    options => $ft_options,
  }

  haproxy::backend { 'bk_nova_public':
    mode    => 'http',
    options => {
      'balance' => 'source',
      'option'  => [
        'tcplog',
        'tcpka',
        'httpchk',
      ],
    },
  }
}