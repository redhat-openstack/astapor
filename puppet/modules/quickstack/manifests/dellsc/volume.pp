define quickstack::dellsc::volume (
  $index,
  $backend_section_name_array,
  $backend_dell_sc_name_array,
  $dell_sc_san_ip_array,
  $dell_sc_san_login_array,
  $dell_sc_san_password_array,
  $dell_sc_iscsi_ip_address_array,
  $dell_sc_iscsi_port_array,
  $dell_sc_ssn_array,
  $dell_sc_api_port_array,
  $dell_sc_server_folder_array,
  $dell_sc_volume_folder_array
) {

  if($index >= 0)
  {
    $backend_section_name = $backend_section_name_array[$index]
    $backend_dell_sc_name = $backend_dell_sc_name_array[$index]
    $dell_sc_san_ip = $dell_sc_san_ip_array[$index]
    $dell_sc_san_login = $dell_sc_san_login_array[$index]
    $dell_sc_san_password = $dell_sc_san_password_array[$index]
    $dell_sc_iscsi_ip_address = $dell_sc_iscsi_ip_address_array[$index]
    $dell_sc_iscsi_port = $dell_sc_iscsi_port_array[$index]
    $dell_sc_ssn = $dell_sc_ssn_array[$index]
    $dell_sc_api_port = $dell_sc_api_port_array[$index]
    $dell_sc_server_folder = $dell_sc_server_folder_array[$index]
    $dell_sc_volume_folder = $dell_sc_volume_folder_array[$index]

    cinder::backend::dellsc_iscsi { $backend_section_name:
      volume_backend_name   => $backend_dell_sc_name,
      san_ip                => $dell_sc_san_ip,
      san_login             => $dell_sc_san_login,
      san_password          => $dell_sc_san_password,
      iscsi_ip_address      => $dell_sc_iscsi_ip_address,
      iscsi_port            => $dell_sc_iscsi_port,
      dell_sc_ssn           => $dell_sc_ssn,
      dell_sc_api_port      => $dell_sc_api_port,
      dell_sc_server_folder => $dell_sc_server_folder,
    }

    #recurse
    $next = $index -1
    quickstack::dellsc::volume {$next:
      index                          => $next,
      backend_section_name_array     => $backend_section_name_array,
      backend_dell_sc_name_array     => $backend_dell_sc_name_array,
      dell_sc_san_ip_array           => $dell_sc_san_ip_array,
      dell_sc_san_login_array        => $dell_sc_san_login_array,
      dell_sc_san_password_array     => $dell_sc_san_password_array,
      dell_sc_iscsi_ip_address_array => $dell_sc_iscsi_ip_address_array,
      dell_sc_iscsi_port_array       => $dell_sc_iscsi_port_array,
      dell_sc_ssn_array              => $dell_sc_ssn_array,
      dell_sc_api_port_array         => $dell_sc_api_port_array,
      dell_sc_server_folder_array    => $dell_sc_server_folder_array,
      dell_sc_volume_folder_array    => $dell_sc_volume_folder_array
    }
  }
}
