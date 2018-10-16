# Sensu checks to monitor VMs stuck in different states
class profile::sensu::checks::openstack::vmstate {
  $openstack_api = hiera('ntnuopenstack::endpoint::public')

  sensu::check { 'openstack-vm-scheduling':
    command     => "/etc/sensu/plugins/extra/check_os_vm_state.sh -p :::os.password::: -u ${openstack_api}:5000/v3 -s scheduling",
    interval    => 300,
    standalone  => false,
    subscribers => [ 'os-vmstate' ],
  }
  sensu::check { 'openstack-vm-build':
    command     => "/etc/sensu/plugins/extra/check_os_vm_state.sh -p :::os.password::: -u ${openstack_api}:5000/v3 -s build",
    interval    => 300,
    standalone  => false,
    subscribers => [ 'os-vmstate' ],
  }
  sensu::check { 'openstack-vm-spawning':
    command     => "/etc/sensu/plugins/extra/check_os_vm_state.sh -p :::os.password::: -u ${openstack_api}:5000/v3 -s spawning",
    interval    => 300,
    standalone  => false,
    subscribers => [ 'os-vmstate' ],
  }
}
