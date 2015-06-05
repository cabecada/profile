class profile::openstack::neutronserver {
  $password = hiera("profile::mysql::neutronpass")
  $neutron_password = hiera("profile::neutron::keystone::password")
  $nova_password = hiera("profile::nova::keystone::password")
  $allowed_hosts = hiera("profile::mysql::allowed_hosts")
  $keystone_ip = hiera("profile::api::keystone::public::ip")
  $mysql_ip = hiera("profile::mysql::ip")

  $region = hiera("profile::region")
  $admin_ip = hiera("profile::api::neutron::admin::ip")
  $public_ip = hiera("profile::api::neutron::public::ip")
  $vrid = hiera("profile::api::neutron::vrrp::id")
  $vrpri = hiera("profile::api::neutron::vrrp::priority")
  $nova_admin_ip = hiera("profile::api::nova::admin::ip")
  $nova_public_ip = hiera("profile::api::nova::public::ip")
  $service_plugins = hiera("profile::neutron::service_plugins")
  $neutron_vrrp_pass = hiera("profile::neutron::vrrp_pass")
  $nova_metadata_secret = hiera("profile::nova::sharedmetadataproxysecret")

  $vlan_low = hiera("profile::neutron::vlan_low")
  $vlan_high = hiera("profile::neutron::vlan_high")
  
  $rabbit_user = hiera("profile::rabbitmq::rabbituser")
  $rabbit_pass = hiera("profile::rabbitmq::rabbitpass")

  $database_connection = "mysql://neutron:${password}@${mysql_ip}/neutron"
  
  include ::profile::openstack::repo
  
  anchor { "profile::openstack::neutron::begin" : 
    require => [ Anchor["profile::mysqlcluster::end"], ],
  }
  
  class { '::neutron':
    verbose               => true,
    core_plugin           => 'ml2',
    allow_overlapping_ips => true,
    service_plugins       => $service_plugins,
    before                => Anchor["profile::openstack::neutron::end"],
    require               => Anchor["profile::openstack::neutron::begin"],
    rabbit_password       => $rabbit_pass,
    rabbit_user           => $rabbit_user,
    rabbit_host           => 'localhost',
  }
  
  class { 'neutron::db::mysql' :
    password         => $password,
    allowed_hosts    => $allowed_hosts,
    before           => Anchor['profile::openstack::neutron::end'],
    require          => Anchor['profile::openstack::neutron::begin'],
  }

  class { '::neutron::keystone::auth':
    password         => $neutron_password,
    public_address   => $public_ip,
    admin_address    => $admin_ip,
    internal_address => $admin_ip,
    before           => Anchor["profile::openstack::neutron::end"],
    require          => Anchor["profile::openstack::neutron::begin"],
    region           => $region,
  }

  class { '::neutron::agents::metadata':
    auth_password => $neutron_password,
    shared_secret => $nova_metadata_secret,
    auth_url      => "http://${keystone_ip}:35357/v2.0",
    auth_region   => $region,
    metadata_ip   => $admin_ip,
    enabled       => true,
  }
  
  class { '::neutron::server':
    auth_password     => $neutron_password,
    auth_uri          => "http://${keystone_ip}:5000/",
    connection        => $database_connection,
    sync_db           => true,
    before            => Anchor["profile::openstack::neutron::end"],
    require           => Anchor["profile::openstack::neutron::begin"],
  }
  
  class { '::neutron::agents::dhcp':
    #enabled        => false,
    #manage_service => false,
    before         => Anchor["profile::openstack::neutron::end"],
    require        => Anchor["profile::openstack::neutron::begin"],
  }
  
  # Configure nova notifications system
  class { '::neutron::server::notifications':
    nova_admin_password    => $nova_password,
    nova_admin_auth_url    => "http://${keystone_ip}:35357/v2.0",
    nova_region_name       => $region,
    nova_url               => "http://${nova_public_ip}:8774/v2",
    before                 => Anchor["profile::openstack::neutron::end"],
    require                => Class["::nova::keystone::auth"],
  }

  # This plugin configures Neutron for OVS on the server
  # Agent
  class { '::neutron::agents::ml2::ovs':
    bridge_mappings  => ['external:br-ex','physnet-vlan:br-vlan'],
    before           => Anchor["profile::openstack::neutron::end"],
    require          => Anchor["profile::openstack::neutron::begin"],
  }

  # ml2 plugin with vxlan as ml2 driver and ovs as mechanism driver
  class { '::neutron::plugins::ml2':
    type_drivers         => ['vlan', 'flat'],
    tenant_network_types => ['vlan'],
    mechanism_drivers    => ['openvswitch'],
    network_vlan_ranges  => ["physnet-vlan:${vlan_low}:${vlan_high}"],
    before         => Anchor["profile::openstack::neutron::end"],
    require        => Anchor["profile::openstack::neutron::begin"],
  }
  
  class { '::neutron::agents::l3':
    before                           => Anchor["profile::openstack::neutron::end"],
    require                          => Anchor["profile::openstack::neutron::begin"],
    allow_automatic_l3agent_failover => true,
    ha_enabled                       => true,
    ha_vrrp_auth_password            => $neutron_vrrp_pass,
  }
  
  vs_port { "eth0":
    ensure => present,
    bridge => "br-ex",
  }
 # vs_bridge { "br-vlan":
 #   ensure => present,
 # } ->
  vs_port { "eth3":
    ensure => present,
    bridge => "br-vlan",
  }

  keepalived::vrrp::script { 'check_neutron':
    require        => Anchor["profile::openstack::neutron::begin"],
    script => '/usr/bin/killall -0 keystone-all',
  } ->

  keepalived::vrrp::instance { 'admin-neutron':
    interface         => 'eth1',
    state             => 'MASTER',
    virtual_router_id => $vrid,
    priority          => $vrpri,
    auth_type         => 'PASS',
    auth_pass         => $vrrp_password, 
    virtual_ipaddress => [
      "${admin_ip}/32",	
    ],
    track_script      => 'check_keystone',
  } ->

  keepalived::vrrp::instance { 'public-neutron':
    before            => Anchor["profile::openstack::neutron::end"],
    interface         => 'eth0',
    state             => 'MASTER',
    virtual_router_id => $vrid,
    priority          => $vrpri,
    auth_type         => 'PASS',
    auth_pass         => $vrrp_password, 
    virtual_ipaddress => [
      "${public_ip}/32",	
    ],
    track_script      => 'check_keystone',
  }
  
#  cs_primitive { 'neutron_public_ip':
#    primitive_class => 'ocf',
#    primitive_type  => 'IPaddr2',
#    provided_by     => 'heartbeat',
#    parameters      => { 'ip' => $public_ip, 'cidr_netmask' => '24' },
#    operations      => { 'monitor' => { 'interval' => '2s' } },
#  }
#  
#  cs_primitive { 'neutron_private_ip':
#    primitive_class => 'ocf',
#    primitive_type  => 'IPaddr2',
#    provided_by     => 'heartbeat',
#    parameters      => { 'ip' => $private_ip, 'cidr_netmask' => '24' },
#    operations      => { 'monitor' => { 'interval' => '2s' } },
#  }
  
  anchor { "profile::openstack::neutron::end" : }
}
