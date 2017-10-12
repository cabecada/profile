# Installs and configures a puppetmaster 
class profile::services::puppetmaster {
  include ::profile::services::puppetmaster::config
  include ::profile::services::puppetmaster::hiera
  include ::profile::services::puppetmaster::haproxy::backend
  include ::profile::services::puppetmaster::install
  include ::profile::services::puppetmaster::service
}
