# This class installs and configures firewall post.
class profile::baseconfig::firewall::post {
  $action = hiera('profile::firewall::action::final', 'drop')

  if($action == 'log') {
    firewall { '999 drop all':
      proto      => 'all',
      jump       => 'LOG',
      log_level  => '5',
      log_prefix => 'FW-DROP',
      before     => undef,
    }
    firewall { '999 ipv6 drop all':
      proto      => 'all',
      jump       => 'LOG',
      log_level  => '5',
      log_prefix => 'FW-DROP',
      provider   => 'ip6tables',
      before     => undef,
    }
  } else {
    firewall { '999 drop all':
      proto  => 'all',
      action => $action,
      before => undef,
    }
    firewall { '999 ipv6 drop all':
      proto    => 'all',
      action   => $action,
      provider => 'ip6tables',
      before   => undef,
    }
  }
}
