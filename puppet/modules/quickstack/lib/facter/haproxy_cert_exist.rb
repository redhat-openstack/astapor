if FileTest.file?("/etc/ssl/horizon.pem")
    Facter.add(:haproxy_cert_exist) do
        setcode { true }
    end
end
