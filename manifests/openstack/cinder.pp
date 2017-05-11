# Installs and configures the cinder service on an openstack controller node in
# the SkyHiGh architecture
class profile::openstack::cinder {
  $password = hiera('profile::mysql::cinderpass')
  $keystone_password = hiera('profile::cinder::keystone::password')
  $allowed_hosts = hiera('profile::mysql::allowed_hosts')
  $mysql_ip = hiera('profile::mysql::ip')
  $ceph_key = hiera('profile::ceph::nova_key')
  $ceph_uuid = hiera('profile::ceph::nova_uuid')
  $memcached_ip = hiera('profile::memcache::ip')

  $region = hiera('profile::region')
  $keystone_ip = hiera('profile::api::keystone::public::ip')
  $keystone_admin_ip = hiera('profile::api::keystone::admin::ip')
  $keystone_admin_pass = hiera('profile::keystone::admin_password')
  $admin_ip = hiera('profile::api::cinder::admin::ip')
  $public_ip = hiera('profile::api::cinder::public::ip')
  $vrrp_password = hiera('profile::keepalived::vrrp_password')
  $vrid = hiera('profile::api::cinder::vrrp::id')
  $vrpri = hiera('profile::api::cinder::vrrp::priority')

  $rabbit_ip = hiera('profile::rabbitmq::ip')
  $rabbit_user = hiera('profile::rabbitmq::rabbituser')
  $rabbit_pass = hiera('profile::rabbitmq::rabbitpass')

  $database_connection = "mysql://cinder:${password}@${mysql_ip}/cinder"

  $public_if = hiera('profile::interfaces::public')
  $management_if = hiera('profile::interfaces::management')
  $management_ip = getvar("::ipaddress_${management_if}")

  require ::profile::services::rabbitmq
  require ::profile::mysql::cluster
  require ::profile::services::keepalived
  require ::profile::openstack::repo

  anchor { 'profile::openstack::cinder::begin' :
    require => [
      Anchor['profile::ceph::monitor::end'],
    ],
  }

  ceph_config {
      'client.nova/key':              value => $ceph_key;
  }

  class { '::cinder':
    database_connection => $database_connection,
    rabbit_host         => $rabbit_ip,
    rabbit_userid       => $rabbit_user,
    rabbit_password     => $rabbit_pass,
    enable_v1_api       => false,
    enable_v2_api       => false,
  }

  class  { '::cinder::keystone::auth':
    password        => $keystone_password,
    #public_url      => "http://${public_ip}:8776/v1/%(tenant_id)s",
    #internal_url    => "http://${admin_ip}:8776/v1/%(tenant_id)s",
    #admin_url       => "http://${admin_ip}:8776/v1/%(tenant_id)s",
    #public_url_v2   => "http://${public_ip}:8776/v2/%(tenant_id)s",
    #internal_url_v2 => "http://${admin_ip}:8776/v2/%(tenant_id)s",
    #admin_url_v2    => "http://${admin_ip}:8776/v2/%(tenant_id)s",
    public_url_v3   => "http://${public_ip}:8776/v3/%(tenant_id)s",
    internal_url_v3 => "http://${admin_ip}:8776/v3/%(tenant_id)s",
    admin_url_v3    => "http://${admin_ip}:8776/v3/%(tenant_id)s",
    region          => $region,
    before          => Anchor['profile::openstack::cinder::end'],
    require         => Anchor['profile::openstack::cinder::begin'],
  }

  class { '::cinder::db::mysql' :
    password      => $password,
    allowed_hosts => $allowed_hosts,
    before        => Anchor['profile::openstack::cinder::end'],
    require       => Anchor['profile::openstack::cinder::begin'],
  }

  class { '::cinder::db::sync': }

  class { '::cinder::api':
    keystone_password   => $keystone_password,
    #auth_uri           => "http://${keystone_ip}:5000/",
    keystone_enabled    => false,
    auth_strategy       => '',
    enabled             => true,
    default_volume_type => 'Normal',
  }

  class { '::cinder::keystone::authtoken':
    auth_url          => "http://${keystone_admin_ip}:35357",
    auth_uri          => "http://${keystone_ip}:5000",
    memcached_servers => $memcached_ip,
    region_name       => $region,
  }

  class { '::cinder::scheduler':
    enabled          => true,
  }

  class { 'cinder::volume': }

  class { 'cinder::volume::rbd':
    rbd_pool        => 'volumes',
    rbd_user        => 'nova',
    rbd_secret_uuid => $ceph_uuid,
  }

  keepalived::vrrp::script { 'check_cinder':
    script  => '/usr/bin/killall -0 cinder-api',
    before  => Anchor['profile::openstack::cinder::end'],
    require => Anchor['profile::openstack::cinder::begin'],
  }

  keepalived::vrrp::instance { 'admin-cinder':
    interface         => $management_if,
    state             => 'MASTER',
    virtual_router_id => $vrid,
    priority          => $vrpri,
    auth_type         => 'PASS',
    auth_pass         => $vrrp_password,
    virtual_ipaddress => [
      "${admin_ip}/32",
    ],
    track_script      => 'check_cinder',
    before            => Anchor['profile::openstack::cinder::end'],
    require           => Anchor['profile::openstack::cinder::begin'],
  }

  keepalived::vrrp::instance { 'public-cinder':
    interface         => $public_if,
    state             => 'MASTER',
    virtual_router_id => $vrid,
    priority          => $vrpri,
    auth_type         => 'PASS',
    auth_pass         => $vrrp_password,
    virtual_ipaddress => [
      "${public_ip}/32",
    ],
    track_script      => 'check_cinder',
    before            => Anchor['profile::openstack::cinder::end'],
    require           => Anchor['profile::openstack::cinder::begin'],
  }

  ceph::key { 'client.cinder':
    secret  => $ceph_key,
    cap_mon => 'allow r',
    cap_osd =>
      'allow class-read object_prefix rbd_children, allow rwx pool=cinder',
    inject  => true,
    before  => Anchor['profile::openstack::cinder::end'],
    require => Anchor['profile::openstack::cinder::begin'],
  }

  sudo::conf { 'cinder_sudoers':
    ensure         => 'present',
    source         => 'puppet:///modules/profile/sudo/cinder_sudoers',
    sudo_file_name => 'cinder_sudoers',
  }

  anchor { 'profile::openstack::cinder::end' : }
}
