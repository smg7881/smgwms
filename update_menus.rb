menu_mapping = {
  'OM_CUST_SYS_CFG' => '/om/customer_system_configs',
  'OM_CUST_OFCR_MGT' => '/om/customer_order_officers',
  'OM_ORD_OFCR_MGT' => '/om/order_officers',
  'OM_PRE_FILE_UP' => '/om/pre_order_file_uploads',
  'OM_PRE_RECP_MGT' => '/om/pre_order_receptions',
  'OM_PRE_ERR_MGT' => '/om/pre_order_reception_errors',
  'OM_ORD_INQ' => '/om/order_inquiries',
  'OM_SVC_ORD_MGT' => '/om/service_orders',
  'OM_INT_ORD_MGT' => '/om/internal_orders',
  'OM_WAIT_ORD_MGT' => '/om/waiting_orders',
  'OM_MAN_DONE_MGT' => '/om/order_manual_completions',
  'OM_WORK_PROG_INQ' => '/om/order_work_progresses',
  'OM_MOD_HIST_INQ' => '/om/order_modification_histories',
  'OM_TRMS_HIST_INQ' => '/om/execution_order_transmissions'
}

menu_mapping.each do |menu_cd, new_url|
  menu = AdmMenu.find_by(menu_cd: menu_cd)
  if menu
    menu.update(menu_url: new_url)
    puts "Updated #{menu_cd} to #{new_url}"
  end
end

# Delete duplicates created mistakenly
duplicates = [
  'OM_CUST_SYS_CONF', 'OM_CUST_ORD_OFCR', 'OM_INTERNAL_ORD',
  'OM_PRE_ORD_RECP', 'OM_PRE_ORD_ERR', 'OM_PRE_ORD_FILE_UL',
  'OM_ORD_OFCR', 'OM_ORD_MANL_CMPT'
]

AdmMenu.where(menu_cd: duplicates).destroy_all
puts "Deleted duplicate menus: #{duplicates.join(', ')}"
