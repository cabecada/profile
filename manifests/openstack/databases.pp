# Defines the databases used by openstack
class profile::openstack::databases {
  include ::profile::openstack::cinder::database
  include ::profile::openstack::glance::database
  include ::profile::openstack::heat::database
  include ::profile::openstack::keystone::database
  include ::profile::openstack::neutron::database
  include ::profile::openstack::nova::database
}