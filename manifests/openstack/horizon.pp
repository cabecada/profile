# Installs and configures horizon
class profile::openstack::horizon {
  # Determine if SSL should be configured
  $ssl_cert = hiera('profile::horizon::ssl_cert', false)

  # Try to retrieve IP-addresses for keystone and horizon.
  $horizon_ip = hiera('profile::api::horizon::public::ip', false)
  $keystone_ip = hiera('profile::api::keystone::public::ip', false)

  # Try to retrieve endpoint-names
  $keystone_endpoint = hiera('profile::openstack::endpoint::internal', false)

  # Horizon settings
  $server_name = hiera('profile::horizon::server_name')
  $django_secret = hiera('profile::horizon::django_secret')
  $ldap_name = hiera('profile::keystone::ldap_backend::name')
  $memcache_servers = hiera_array('profile::memcache::servers', undef)

  # Should be removed:
  $controller_api = hiera('controller::api::addresses')
  $horizon_allowed_hosts = hiera('profile::horizon::allowed_hosts')
  $horizon_server_aliases = hiera('profile::horizon::server_aliases')

  include ::profile::services::apache::firewall
  require ::profile::openstack::repo

  # If we should serve horizon over SSL:
  if($ssl_cert) {
    # Install horizon-certificates
    require ::profile::openstack::horizon::ssl

    # Configure horizon to use the certificates.
    $ssl_settings = {
      'horizon_cert' => '/etc/ssl/certs/horizon.crt',
      'horizon_key'  => '/etc/ssl/private/horizon.key',
      'horizon_ca'   => '/etc/ssl/certs/CA.crt',
      'listen_ssl'   => true,
    }
  } else {
    $ssl_settings = {}
  }

  # If horizon should be served on a specific IP, configure keepalived to
  # negotiate to get this IP address.
  if($horizon_ip) {
    contain ::profile::openstack::horizon::keepalived
  }

  # Determine which endpoint to use to reach keystone
  if(! $keystone_endpoint and ! $keystone_ip) {
    fail("${name} needs either an IP address or an url to reach keystone")
  } else {
    $keystone_base = pick($keystone_endpoint, "http://${keystone_ip}")
    $keystone_url = "${keystone_base}:5000"
  }

  class { '::horizon':
    allowed_hosts                => [$::fqdn, $server_name],
    cache_server_ip              => $memcache_servers,
    keystone_default_domain      => $ldap_name,
    keystone_multidomain_support => true,
    keystone_url                 => $keystone_url,
    neutron_options              => { enable_firewall => true, },
    secret_key                   => $django_secret,
    server_aliases               => [$::fqdn, $server_name],
    servername                   => $server_name,
    session_timeout              => 7200,
    *                            => $ssl_settings,
  }
}
