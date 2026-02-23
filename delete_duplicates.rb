# delete_duplicates.rb
leftovers = [ 'STD_CODE_APPROVAL', 'STD_CODE_SETTLEMENT', 'SALES_CONTRACT_BASE', 'STD_PURCHASE_CONTRACT' ]
puts "Deleting: #{leftovers}"
AdmMenu.where(menu_cd: leftovers).destroy_all
puts "Deleted."
