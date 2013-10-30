Facter.add("hamysql_active_node") do

  setcode do
    a = Facter::Util::Resolution.exec("/usr/sbin/pcs status | grep mysql-ostk-mysql | perl -p -e 's/^.*Started (\\S*).*$/$1/'")
    b = Facter::Util::Resolution.exec("/usr/sbin/crm_node -n")
    a==b
  end
end
