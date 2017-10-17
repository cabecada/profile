# Installs and configures the glance API
class profile::openstack::glance::api {
  $region = hiera('profile::region')

  $keystone_public_ip = hiera('profile::api::keystone::public::ip')
  $keystone_admin_ip = hiera('profile::api::keystone::admin::ip')
  $glance_public_ip = hiera('profile::api::glance::public::ip')
  $glance_admin_ip = hiera('profile::api::glance::admin::ip')

  $memcached_ip = hiera('profile::memcache::ip')

  $management_if = hiera('profile::interfaces::management')
  $management_ip = hiera("profile::interfaces::${management_if}::address")

  $mysql_pass = hiera('profile::mysql::glancepass')
  $mysql_ip = hiera('profile::mysql::ip')
  $database_connection = "mysql://glance:${mysql_pass}@${mysql_ip}/glance"

  # Firewall settings
  $source_firewall_management_net = hiera('profile::networks::management')

  require ::profile::baseconfig::firewall
  require ::profile::openstack::repo
  require ::profile::openstack::glance::database
  contain ::profile::openstack::glance::keepalived

  firewall { '500 accept incoming admin glance tcp':
    source      => $source_firewall_management_net,
    proto       => 'tcp',
    destination => $glance_admin_ip,
    dport       => '9292',
    action      => 'accept',
  }

  firewall { '500 accept incoming public glance tcp':
    source      => $source_firewall_management_net,
    proto       => 'tcp',
    destination => $glance_public_ip,
    dport       => '9292',
    action      => 'accept',
  }

  class { '::glance::api':
    keystone_password       => $mysql_pass,
    auth_strategy           => '',
    database_connection     => $database_connection,
    registry_host           => $management_ip,
    os_region_name          => $region,
    known_stores            => ['glance.store.rbd.Store'],
    show_image_direct_url   => true,
    show_multiple_locations => true,
    pipeline                => 'keystone',
  }

  class { '::glance::api::authtoken':
    password          => $mysql_pass,
    auth_url          => "http://${keystone_admin_ip}:35357",
    auth_uri          => "http://${keystone_public_ip}:5000",
    memcached_servers => $memcached_ip,
    region_name       => $region,
  }

  class  { '::glance::keystone::auth':
    password     => $mysql_pass,
    public_url   => "http://${glance_public_ip}:9292",
    internal_url => "http://${glance_admin_ip}:9292",
    admin_url    => "http://${glance_admin_ip}:9292",
    region       => $region,
  }

  glance_api_config {
    'DEFAULT/default_store': value => 'rbd';
  }
}
