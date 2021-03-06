# Configure firewall for rabbitmq servers
class profile::services::rabbitmq::firewall {
  require ::firewall

  $management_net = hiera('profile::networks::management::ipv4::prefix')
  $management_netv6 = hiera('profile::networks::management::ipv6::prefix', false)

  firewall { '500 accept incoming rabbitmq':
    source      => $management_net,
    proto       => 'tcp',
    dport       => 5672,
    action      => 'accept',
  }
  firewall { '502 accept incoming rabbitmqcluster':
    source      => $management_net,
    proto       => 'tcp',
    dport       => [4369, 25672],
    action      => 'accept',
  }
  if ( $management_netv6 ) {
    firewall { '500 ipv6 accept incoming rabbitmq':
      source      => $management_netv6,
      proto       => 'tcp',
      dport       => 5672,
      action      => 'accept',
      provider    => 'ip6tables',
    }
    firewall { '502 ipv6 accept incoming rabbitmqcluster':
      source      => $management_netv6,
      proto       => 'tcp',
      dport       => [4369, 25672],
      action      => 'accept',
      provider    => 'ip6tables',
    }
  }
}
