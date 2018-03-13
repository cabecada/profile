# Install and configure ceph-mon
class profile::ceph::monitor {
  $mon_key = hiera('profile::ceph::monitor_key')
  $mgr_key = hiera('profile::ceph::mgr_key')
  $admin_key = hiera('profile::ceph::admin_key')
  $bootstrap_osd_key = hiera('profile::ceph::osd_bootstrap_key')

  $installmunin = hiera('profile::munin::install', true)
  if($installmunin) {
    include ::profile::munin::plugin::ceph
  }

  $installsensu = hiera('profile::sensu::install', true)
  if ($installsensu) {
    include ::profile::sensu::plugin::ceph
  }

  require ::profile::ceph::base

  ceph::mgr { $::hostname :
    key        => $mgr_key,
    inject_key => true,
  }
  ceph::mon { $::hostname:
    key    => $mon_key,
    before => Anchor['profile::ceph::monitor::end']
  }

  Ceph::Key {
    inject         => true,
    inject_as_id   => 'mon.',
    inject_keyring => "/var/lib/ceph/mon/ceph-${::hostname}/keyring",
    before         => Anchor['profile::ceph::monitor::end']
  }
  ceph::key { 'client.admin':
    secret  => $admin_key,
    cap_mon => 'allow *',
    cap_osd => 'allow *',
    cap_mds => 'allow',
    cap_mgr => 'allow *',
    before  => Anchor['profile::ceph::monitor::end']
  }
  ceph::key { 'client.bootstrap-osd':
    secret  => $bootstrap_osd_key,
    cap_mon => 'allow profile bootstrap-osd',
    before  => Anchor['profile::ceph::monitor::end']
  }

  anchor{'profile::ceph::monitor::end':}
}
