# Installs and configures a rabbitmq server for our openstack environment.
class profile::services::rabbitmq {

  include ::profile::services::rabbitmq::firewall
  require ::profile::services::erlang

  # Rabbit credentials
  $rabbituser = hiera('profile::rabbitmq::rabbituser')
  $rabbitpass = hiera('profile::rabbitmq::rabbitpass')
  $secret     = hiera('profile::rabbitmq::rabbitsecret')
  $enable_keepalived = hiera('profile::rabbitmq::keepalived::enable', true)
  $cluster_nodes = hiera('profile::rabbitmq::servers', false)

  if ( $cluster_nodes ) {
    $cluster_config = {
      config_cluster => true,
      cluster_nodes  =>  $cluster_nodes,
    }
  } else {
    $cluster_config = {}
  }

  if ( $enable_keepalived ) {
    require ::profile::services::keepalived::rabbitmq
  } else {
    package { 'keepalived':
      ensure => 'purged',
    }
  }

  if ( $enable_keepalived ) and ( $cluster_nodes ) {
    warning("Both keeaplived and clustering are enabled. You probably don't want that")
  }

  class { '::rabbitmq':
    admin_enable             => false,
    erlang_cookie            => $secret,
    repos_ensure             => true,
    wipe_db_on_cookie_change => true,
    *                        => $cluster_config,
  }
  -> rabbitmq_user { $rabbituser:
    admin    => true,
    password => $rabbitpass,
    provider => 'rabbitmqctl',
  }
  -> rabbitmq_user_permissions { "${rabbituser}@/":
    configure_permission => '.*',
    write_permission     => '.*',
    read_permission      => '.*',
    provider             => 'rabbitmqctl',
  }

  # Install munin plugins for monitoring.
  $install_munin = hiera('profile::munin::install', true)
  if($install_munin) {
    include ::profile::monitoring::munin::plugin::rabbitmq
  }

  # Include rabbitmq configuration for sensu. And the plugin
  $install_sensu = hiera('profile::sensu::install', true)
  if ($install_sensu) {
    include ::profile::services::rabbitmq::sensu
    include ::profile::sensu::plugin::rabbitmq
  }
}
