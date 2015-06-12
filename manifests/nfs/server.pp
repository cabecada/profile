class profile::nfs::server {
  include nfs::server
  nfs::server::export{ '/data/shared':
    ensure  => 'mounted',
    clients => '172.17.1.0/24(rw,insecure,async,no_root_squash) localhost(rw)'
  }
}
