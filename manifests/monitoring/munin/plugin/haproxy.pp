# This class installs the munin plugins which monitors haproxy statistics 
class profile::monitoring::munin::plugin::haproxy {
  ensure_packages ( [
      'liblwp-useragent-determined-perl',
    ], {
      'ensure' => 'present',
    }
  )
  
  munin::plugin { "haproxy_ng":
    ensure => link,
    config => ['env.url http://localhost:9000/haproxy-status;csv;norefresh'],
  }
}
