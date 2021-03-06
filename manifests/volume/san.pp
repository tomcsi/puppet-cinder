# == Class: cinder::volume::san
#
# Configures Cinder volume SAN driver.
# Parameters are particular to each volume driver.
#
# === Parameters
#
# [*volume_driver*]
#   (required) Setup cinder-volume to use volume driver.
#
# [*san_thin_provision*]
#   (Optional) Use thin provisioning for SAN volumes?
#   Defaults to true.
#
# [*san_ip*]
#   (Optional) IP address of SAN controller.
#
# [*san_login*]
#   (Optional) Username for SAN controller.
#   Defaults to 'admin'.
#
# [*san_password*]
#   (Optional) Password for SAN controller.
#
# [*san_private_key*]
#   (Optional) Filename of private key to use for SSH authentication.
#
# [*san_clustername*]
#   (Optional) Cluster name to use for creating volumes.
#
# [*san_ssh_port*]
#   (Optional) SSH port to use with SAN.
#   Defaults to 22.
#
# [*san_is_local*]
#   (Optional) Execute commands locally instead of over SSH
#   use if the volume service is running on the SAN device.
#   Defaults to 'false'.
#
# [*ssh_conn_timeout*]
#   (Optional) SSH connection timeout in seconds.
#   Defaults to '30'.
#
# [*ssh_min_pool_conn*]
#   (Optional) Minimum ssh connections in the pool.
#   Defaults to '1'.
#
# [*ssh_max_pool_conn*]
#   (Optional) Maximum ssh connections in the pool.
#   Defaults to '5'.
#
class cinder::volume::san (
  $volume_driver,
  $san_thin_provision = true,
  $san_ip             = undef,
  $san_login          = 'admin',
  $san_password       = undef,
  $san_private_key    = undef,
  $san_clustername    = undef,
  $san_ssh_port       = 22,
  $san_is_local       = false,
  $ssh_conn_timeout   = 30,
  $ssh_min_pool_conn  = 1,
  $ssh_max_pool_conn  = 5
) {

  cinder::backend::san { 'DEFAULT':
    volume_driver      => $volume_driver,
    san_thin_provision => $san_thin_provision,
    san_ip             => $san_ip,
    san_login          => $san_login,
    san_password       => $san_password,
    san_private_key    => $san_private_key,
    san_clustername    => $san_clustername,
    san_ssh_port       => $san_ssh_port,
    san_is_local       => $san_is_local,
    ssh_conn_timeout   => $ssh_conn_timeout,
    ssh_min_pool_conn  => $ssh_min_pool_conn,
    ssh_max_pool_conn  => $ssh_max_pool_conn,
  }
}
