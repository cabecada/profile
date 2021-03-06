# Haproxy config for redis

class profile::services::redis::haproxy {
  require ::profile::services::haproxy
  include ::profile::services::redis::firewall

  $ipv4 = hiera('profile::haproxy::management::ipv4')
  $ipv6 = hiera('profile::haproxy::management::ipv6', false)
  $redisauth = hiera('profile::redis::masterauth')

  profile::services::haproxy::tools::collect { 'bk_redis': }

  $ft_options = {
    'default_backend' => 'bk_redis',
    'option'          => [
      'clitcpka',
      'srvtcpka',
    ],
  }

  if($ipv6) {
    haproxy::frontend { 'ft_redis':
      bind    => {
        "${ipv4}:6379" => [],
        "${ipv6}:6379" => [],
      },
      mode    => 'tcp',
      options => $ft_options,
    }
  } else {
    haproxy::frontend { 'ft_redis':
      ipaddress => $ipv4,
      ports     => '6379',
      mode      => 'tcp',
      options   => $ft_options,
    }
  }

  haproxy::backend { 'bk_redis':
    options => {
      'option'    => [
        'log-health-checks',
        'tcp-check',
        'tcplog',
      ],
      'tcp-check' => [
        'connect',
        "send AUTH\\ ${redisauth}\\r\\n",
        'expect string +OK',
        'send PING\r\n',
        'expect string +PONG',
        'send info\ replication\r\n',
        'expect string role:master',
        'send QUIT\r\n',
        'expect string +OK',
      ],
    },
  }
}
