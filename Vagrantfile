# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.require_plugin 'vagrant-aws'
Vagrant.configure('2') do |config|

  #
  # Boxes to use.
  # 

  # Puppet Labs CentOS 6.4 for VirtualBox
  config.vm.provider :virtualbox do |virtualbox, override|
    override.vm.box     = 'puppetlabs-centos-65-x64-vbox'
    override.vm.box_url = 'http://puppet-vagrant-boxes.puppetlabs.com/centos-65-x64-virtualbox-puppet.box'
  end

  # Puppet Labs CentOS 6.4 for VMWare Fusion
  config.vm.provider :vmware_fusion do |fusion, override|
    override.vm.box     = 'puppetlabs-centos-65-x64-fusion'
    override.vm.box_url = 'http://puppet-vagrant-boxes.puppetlabs.com/centos-64-x64-fusion503.box'
  end

  # Amazon Linux AMI
  config.vm.provider :aws do |aws, override|
    override.vm.box     = 'huit-amazon-linux-generic'
    override.vm.box_url = 'https://raw.github.com/huit/huit-vagrant-boxes/master/aws/amazon-linux-generic.box'
  end


  #
  # Define the Foreman server
  # 
  config.vm.define "foreman", primary: true do |foreman|

#    foreman.vm.box = override.vm.box 

    # Forward standard ports (local only, does not run under AWS)    
    foreman.vm.network :forwarded_port, guest: 80,  host: 8080, auto_correct: true
    foreman.vm.network :forwarded_port, guest: 443, host: 8443, auto_correct: true

    # provide a 2nd network
    foreman.vm.network "private_network", ip: "192.168.1.2", virtualbox__intnet: "private"

    # Install r10k using the shell provisioner and download the Puppet modules
    foreman.vm.provision :shell, :path => 'bootstrap/foreman.sh'
  end


  #
  # Define the Controller server
  # 

  config.vm.define "controller", primary: true do |controller|

    # Forward standard ports (local only, does not run under AWS)    
    controller.vm.network :forwarded_port, guest: 80,  host: 9080, auto_correct: true
    controller.vm.network :forwarded_port, guest: 443, host: 9443, auto_correct: true
    
    controller.vm.network :forwarded_port, guest: 5000,  host: 5000, auto_correct: true
    controller.vm.network :forwarded_port, guest: 35357,  host: 35357, auto_correct: true 
    
    controller.vm.network :forwarded_port, guest: 9292,  host: 9292, auto_correct: true

    controller.vm.network :forwarded_port, guest: 8773,  host: 8773, auto_correct: true  
    controller.vm.network :forwarded_port, guest: 8774,  host: 8774, auto_correct: true  
    controller.vm.network :forwarded_port, guest: 8775,  host: 8775, auto_correct: true  
    controller.vm.network :forwarded_port, guest: 8776,  host: 8776, auto_correct: true 
    controller.vm.network :forwarded_port, guest: 8777,  host: 8777, auto_correct: true 
    controller.vm.network :forwarded_port, guest: 6080,  host: 6080, auto_correct: true 

    controller.vm.network :forwarded_port, guest: 9696,  host: 9696, auto_correct: true    

    controller.vm.network :forwarded_port, guest: 8000,  host: 8000, auto_correct: true
    controller.vm.network :forwarded_port, guest: 8004,  host: 8004, auto_correct: true

    # provide a 2nd network
    controller.vm.network "private_network", ip: "192.168.1.3", virtualbox__intnet: "private"

    # Install r10k using the shell provisioner and download the Puppet modules
    controller.vm.provision :shell, :path => 'bootstrap/node.sh', :args => 'controller'
  end


  #
  # Define the Compute server
  # 

  config.vm.define "compute", primary: true do |compute|

    # provide a 2nd network
    compute.vm.network "private_network", ip: "192.168.1.4", virtualbox__intnet: "private"

    # Install r10k using the shell provisioner and download the Puppet modules
    compute.vm.provision :shell, :path => 'bootstrap/node.sh', :args => 'compute'
  end


  #
  # Define the Networker server
  # 

  config.vm.define "networker", primary: true do |networker|

    # provide a 2nd network
    networker.vm.network "private_network", ip: "192.168.1.5", virtualbox__intnet: "private"

    # Install r10k using the shell provisioner and download the Puppet modules
    networker.vm.provision :shell, :path => 'bootstrap/node.sh', :args => 'networker'
  end

end
